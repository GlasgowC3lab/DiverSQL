WITH
    sales_combined AS (
        SELECT
            ss.ss_sold_date_sk AS date_sk,
            ss.ss_store_sk AS location_sk,
            ss.ss_item_sk AS item_sk,
            ss.ss_quantity AS quantity,
            ss.ss_net_profit AS net_profit,
            'store' AS channel,
            ss.ss_promo_sk AS promo_sk
        FROM store_sales ss
        UNION ALL
        SELECT
            ws.ws_sold_date_sk AS date_sk,
            ws.ws_warehouse_sk AS location_sk,
            ws.ws_item_sk AS item_sk,
            ws.ws_quantity AS quantity,
            ws.ws_net_profit AS net_profit,
            'web' AS channel,
            ws.ws_promo_sk AS promo_sk
        FROM web_sales ws
    ),
    item_agg AS (
        SELECT
            sc.location_sk,
            sc.item_sk,
            SUM(sc.net_profit) AS total_profit,
            SUM(sc.quantity) AS total_quantity,
            COUNT(*) AS txn_count,
            MAX(sc.date_sk) AS latest_date_sk,
            MIN(sc.date_sk) AS earliest_date_sk,
            CASE WHEN SUM(sc.quantity) = 0 THEN NULL
                 ELSE SUM(sc.net_profit) / NULLIF(SUM(sc.quantity),0)
            END AS profit_per_qty,
            array_join(array_agg(sc.channel ORDER BY sc.channel), ',') AS channels
        FROM sales_combined sc
        GROUP BY sc.location_sk, sc.item_sk
    ),
    ranked_items AS (
        SELECT
            ia.*,
            RANK() OVER (PARTITION BY ia.location_sk ORDER BY ia.total_profit DESC) AS profit_rank
        FROM item_agg ia
    ),
    store_info AS (
        SELECT
            s.s_store_sk,
            s.s_store_name,
            s.s_city,
            s.s_state,
            COALESCE(s.s_tax_percentage, 0) AS tax_pct,
            CONCAT(s.s_city, ', ', s.s_state) AS location_label
        FROM store s
    ),
    warehouse_info AS (
        SELECT
            w.w_warehouse_sk,
            w.w_warehouse_name,
            w.w_city,
            w.w_state,
            0.0 AS tax_pct,
            CONCAT(w.w_city, ', ', w.w_state) AS location_label
        FROM warehouse w
    ),
    item_info AS (
        SELECT
            i.i_item_sk,
            i.i_product_name
        FROM item i
    ),
    location_sales AS (
        SELECT
            ri.location_sk,
            COALESCE(si.s_store_name, wi.w_warehouse_name, 'UNKNOWN') AS location_name,
            COALESCE(si.location_label, wi.location_label, 'UNKNOWN') AS location_label,
            ri.item_sk,
            ii.i_product_name,
            ri.total_profit,
            ri.total_quantity,
            ri.txn_count,
            ri.profit_per_qty,
            ri.channels,
            ri.profit_rank,
            ri.latest_date_sk,
            ri.earliest_date_sk,
            (ri.total_profit * (1 + COALESCE(si.tax_pct, wi.tax_pct, 0) / 100.0)) AS profit_with_tax,
            CASE
                WHEN ri.total_quantity > 1000 THEN 'BULK'
                WHEN ri.total_quantity BETWEEN 100 AND 1000 THEN 'MEDIUM'
                ELSE 'SMALL'
            END AS quantity_bucket,
            (COALESCE(NULLIF(ri.total_quantity, 0), -1) * 100) AS quantity_score
        FROM ranked_items ri
        LEFT JOIN store_info si ON ri.location_sk = si.s_store_sk
        LEFT JOIN warehouse_info wi ON ri.location_sk = wi.w_warehouse_sk
        LEFT JOIN item_info ii ON ri.item_sk = ii.i_item_sk
        WHERE ri.profit_rank <= 5
    ),
    inventory_exists AS (
        SELECT
            ls.location_sk,
            ls.item_sk,
            CASE WHEN EXISTS (
                SELECT 1
                FROM inventory inv
                WHERE inv.inv_warehouse_sk = ls.location_sk
                  AND inv.inv_item_sk = ls.item_sk
                  AND inv.inv_quantity_on_hand > 0
            ) THEN 1 ELSE 0 END AS has_inventory
        FROM location_sales ls
    ),
    returns_agg AS (
        SELECT
            sr.sr_store_sk AS location_sk,
            sr.sr_item_sk AS item_sk,
            SUM(sr.sr_return_quantity) AS return_qty,
            SUM(sr.sr_net_loss) AS return_loss
        FROM store_returns sr
        GROUP BY sr.sr_store_sk, sr.sr_item_sk
        UNION ALL
        SELECT
            wr.wr_web_page_sk AS location_sk,
            wr.wr_item_sk AS item_sk,
            SUM(wr.wr_return_quantity) AS return_qty,
            SUM(wr.wr_net_loss) AS return_loss
        FROM web_returns wr
        GROUP BY wr.wr_web_page_sk, wr.wr_item_sk
    ),
    promo_max AS (
        SELECT
            ls.location_sk,
            ls.item_sk,
            (SELECT MAX(p.p_cost)
             FROM promotion p
             WHERE p.p_item_sk = ls.item_sk
               AND ls.latest_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk) AS max_promo_cost
        FROM location_sales ls
    )
SELECT
    ls.location_sk,
    ls.location_name,
    ls.location_label,
    ls.item_sk,
    ls.i_product_name,
    ls.total_profit,
    ls.total_quantity,
    ls.txn_count,
    ls.profit_per_qty,
    ls.channels,
    ls.profit_with_tax,
    ls.quantity_bucket,
    ls.quantity_score,
    ic.has_inventory,
    COALESCE(ra.return_qty, 0) AS total_return_qty,
    COALESCE(ra.return_loss, 0) AS total_return_loss,
    pm.max_promo_cost,
    (SELECT COUNT(*) FROM catalog_sales cs WHERE cs.cs_item_sk = ls.item_sk) AS catalog_sales_count,
    CASE
        WHEN REGEXP_LIKE(CAST(ls.item_sk AS VARCHAR), '^1[0-9]{6}$') THEN 'StartsWith1'
        ELSE 'Other'
    END AS sku_category,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM (SELECT cs.cs_item_sk FROM catalog_sales cs
                  INTERSECT
                  SELECT cr.cr_item_sk FROM catalog_returns cr) AS inter
            WHERE inter.cs_item_sk = ls.item_sk
        ) THEN TRUE ELSE FALSE END AS sold_in_both_catalog,
    CASE
        WHEN ic.has_inventory = 0 THEN NULL
        ELSE ((ls.total_profit - COALESCE(ra.return_loss, 0))
              * (1 + COALESCE(ls.quantity_score, 0) / 1000.0)
              + COALESCE(pm.max_promo_cost, 0))
    END AS adjusted_profit_metric,
    pe.promo_email_channels
FROM location_sales ls
LEFT JOIN inventory_exists ic ON ls.location_sk = ic.location_sk AND ls.item_sk = ic.item_sk
LEFT JOIN returns_agg ra ON ls.location_sk = ra.location_sk AND ls.item_sk = ra.item_sk
LEFT JOIN promo_max pm ON ls.location_sk = pm.location_sk AND ls.item_sk = pm.item_sk
CROSS JOIN LATERAL (
    SELECT
        array_join(array_agg(p.p_channel_email ORDER BY p.p_channel_email), ',') AS promo_email_channels
    FROM promotion p
    WHERE p.p_item_sk = ls.item_sk
) AS pe
WHERE
    (ls.quantity_bucket = 'BULK' OR ls.profit_per_qty IS NOT NULL)
    AND EXISTS (
        SELECT 1
        FROM date_dim d
        WHERE d.d_date_sk = ls.latest_date_sk
          AND d.d_year BETWEEN 1998 AND 2002
          AND d.d_holiday = 'N'
    )
    AND (ls.location_name IS NOT NULL OR ls.location_label LIKE '%UNKNOWN%')
    AND ls.item_sk NOT IN (
        SELECT cr.cr_item_sk FROM catalog_returns cr WHERE cr.cr_return_quantity > 0
    )
    AND ls.item_sk IN (
        SELECT cs.cs_item_sk FROM catalog_sales cs
        INTERSECT
        SELECT cr.cr_item_sk FROM catalog_returns cr
    )
    AND NOT EXISTS (
        SELECT 1
        FROM (SELECT cs.cs_item_sk FROM catalog_sales cs
              EXCEPT
              SELECT cr.cr_item_sk FROM catalog_returns cr) AS diff
        WHERE diff.cs_item_sk = ls.item_sk
    )
ORDER BY ls.location_sk, ls.profit_rank, ls.item_sk

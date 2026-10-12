WITH
    last_six_months AS (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_date >= date_add('month', -6, DATE '2024-10-01')
          AND d_date <= DATE '2024-10-01'
    ),
    combined_sales AS (
        SELECT 
            ss.ss_item_sk AS item_sk,
            ss.ss_sold_date_sk AS date_sk,
            ss.ss_store_sk AS store_sk,
            ss.ss_quantity AS quantity,
            ss.ss_sales_price AS sales_price,
            ss.ss_net_paid AS net_paid,
            ss.ss_net_profit AS net_profit,
            'store' AS channel
        FROM store_sales ss
        JOIN last_six_months lsm ON ss.ss_sold_date_sk = lsm.d_date_sk

        UNION ALL

        SELECT 
            cs.cs_item_sk AS item_sk,
            cs.cs_sold_date_sk AS date_sk,
            cs.cs_call_center_sk AS store_sk,
            cs.cs_quantity AS quantity,
            cs.cs_sales_price AS sales_price,
            cs.cs_net_paid AS net_paid,
            cs.cs_net_profit AS net_profit,
            'catalog' AS channel
        FROM catalog_sales cs
        JOIN last_six_months lsm ON cs.cs_sold_date_sk = lsm.d_date_sk

        UNION ALL

        SELECT 
            ws.ws_item_sk AS item_sk,
            ws.ws_sold_date_sk AS date_sk,
            ws.ws_web_page_sk AS store_sk,
            ws.ws_quantity AS quantity,
            ws.ws_sales_price AS sales_price,
            ws.ws_net_paid AS net_paid,
            ws.ws_net_profit AS net_profit,
            'web' AS channel
        FROM web_sales ws
        JOIN last_six_months lsm ON ws.ws_sold_date_sk = lsm.d_date_sk
    ),
    item_channel_agg AS (
        SELECT 
            cs.item_sk,
            i.i_category,
            i.i_class,
            i.i_brand,
            cs.channel,
            COUNT(DISTINCT cs.date_sk) AS active_days,
            SUM(cs.quantity) AS total_qty,
            SUM(cs.sales_price * cs.quantity) AS total_sales_value,
            SUM(cs.net_paid) AS total_net_paid,
            SUM(cs.net_profit) AS total_net_profit,
            CASE 
                WHEN SUM(cs.sales_price * cs.quantity) = 0 THEN NULL
                ELSE SUM(cs.net_profit) / SUM(cs.sales_price * cs.quantity)
            END AS profit_margin
        FROM combined_sales cs
        LEFT JOIN item i ON cs.item_sk = i.i_item_sk
        GROUP BY cs.item_sk, i.i_category, i.i_class, i.i_brand, cs.channel
    ),
    ranked_items AS (
        SELECT 
            ic.*,
            ROW_NUMBER() OVER (PARTITION BY ic.i_category ORDER BY ic.total_net_profit DESC) AS rank_in_category,
            LAG(ic.total_net_profit) OVER (PARTITION BY ic.i_category ORDER BY ic.total_net_profit DESC) AS prev_profit,
            CASE 
                WHEN LAG(ic.total_net_profit) OVER (PARTITION BY ic.i_category ORDER BY ic.total_net_profit DESC) IS NULL THEN NULL
                ELSE (ic.total_net_profit - LAG(ic.total_net_profit) OVER (PARTITION BY ic.i_category ORDER BY ic.total_net_profit DESC))
                     / NULLIF(LAG(ic.total_net_profit) OVER (PARTITION BY ic.i_category ORDER BY ic.total_net_profit DESC), 0)
            END AS profit_change_ratio
        FROM item_channel_agg ic
    ),
    top_items AS (
        SELECT 
            ri.*,
            CASE 
                WHEN ri.total_net_profit > 0 THEN 'POSITIVE' 
                ELSE 'NEGATIVE' 
            END AS profit_indicator,
            CONCAT(ri.i_brand, ' - ', ri.i_category, ' - ', COALESCE(i.i_product_name, 'UNKNOWN')) AS full_item_desc
        FROM ranked_items ri
        LEFT JOIN item i ON ri.item_sk = i.i_item_sk
        WHERE ri.rank_in_category <= 3
          AND ri.total_net_profit = (
                SELECT MAX(r2.total_net_profit)
                FROM ranked_items r2
                WHERE r2.i_brand = ri.i_brand
                  AND r2.i_category = ri.i_category
            )
    ),
    store_agg AS (
        SELECT 
            s.s_store_id,
            s.s_city,
            s.s_state,
            COUNT(DISTINCT cs.date_sk) AS store_active_days,
            SUM(cs.quantity) AS store_total_qty,
            SUM(cs.sales_price * cs.quantity) AS store_total_sales,
            SUM(cs.net_profit) AS store_total_profit,
            AVG(cs.net_profit) AS avg_net_profit_per_txn
        FROM store s
        LEFT JOIN combined_sales cs ON s.s_store_sk = cs.store_sk AND cs.channel = 'store'
        GROUP BY s.s_store_id, s.s_city, s.s_state
    ),
    combined_result AS (
        SELECT 
            ti.item_sk,
            ti.full_item_desc,
            ti.i_brand,
            ti.i_category,
            ti.channel,
            ti.total_qty,
            ti.total_sales_value,
            ti.total_net_profit,
            ti.profit_margin,
            ti.rank_in_category,
            ti.profit_change_ratio,
            ti.profit_indicator,
            NULL AS store_id,
            NULL AS store_city,
            NULL AS store_state,
            NULL AS store_active_days,
            NULL AS store_total_qty,
            NULL AS store_total_sales,
            NULL AS store_total_profit,
            NULL AS avg_net_profit_per_txn
        FROM top_items ti

        UNION ALL

        SELECT 
            NULL AS item_sk,
            NULL AS full_item_desc,
            NULL AS i_brand,
            NULL AS i_category,
            NULL AS channel,
            NULL AS total_qty,
            NULL AS total_sales_value,
            NULL AS total_net_profit,
            NULL AS profit_margin,
            NULL AS rank_in_category,
            NULL AS profit_change_ratio,
            NULL AS profit_indicator,
            sa.s_store_id AS store_id,
            sa.s_city AS store_city,
            sa.s_state AS store_state,
            sa.store_active_days,
            sa.store_total_qty,
            sa.store_total_sales,
            sa.store_total_profit,
            sa.avg_net_profit_per_txn
        FROM store_agg sa
    )
SELECT *
FROM combined_result
ORDER BY total_net_profit DESC NULLS LAST, store_total_profit DESC NULLS LAST
LIMIT 200

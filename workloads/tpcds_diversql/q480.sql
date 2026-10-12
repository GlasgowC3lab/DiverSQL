WITH
    -- Pre‑aggregate inventory (sample 10% of rows)
    inventory_agg AS (
        SELECT
            inv_item_sk,
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory TABLESAMPLE BERNOULLI (10)
        GROUP BY inv_item_sk, inv_warehouse_sk
    ),
    -- Distinct items sold in catalog and in stores for the year 2001
    catalog_sales_items AS (
        SELECT DISTINCT cs_item_sk
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    store_sales_items AS (
        SELECT DISTINCT ss_item_sk
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    -- Items that appear in both streams
    common_items AS (
        SELECT cs_item_sk AS item_sk FROM catalog_sales_items
        INTERSECT
        SELECT ss_item_sk AS item_sk FROM store_sales_items
    ),
    -- Join catalog side (many tables)
    catalog_joined AS (
        SELECT
            cs.cs_order_number,
            cs.cs_sold_date_sk,
            cs.cs_item_sk,
            cs.cs_quantity,
            cs.cs_net_paid,
            cr.cr_return_quantity,
            cr.cr_net_loss,
            i.i_item_id,
            i.i_category,
            p.p_promo_name,
            d.d_year,
            hd.hd_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            ca.ca_state,
            r.r_reason_desc,
            w.w_warehouse_name,
            inv.total_qty
        FROM catalog_sales cs
        JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
        JOIN item i
            ON cs.cs_item_sk = i.i_item_sk
        JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        JOIN date_dim d
            ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca
            ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN inventory_agg inv
            ON inv.inv_item_sk = cs.cs_item_sk
               AND inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE cs.cs_item_sk IN (SELECT item_sk FROM common_items)
    ),
    -- Join store side (many tables, re‑using some dimensions under different aliases)
    store_joined AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_sold_date_sk AS sold_date_sk,
            ss.ss_item_sk,
            ss.ss_quantity,
            ss.ss_net_paid,
            sr.sr_return_quantity,
            sr.sr_net_loss,
            i2.i_item_id,
            i2.i_category,
            p2.p_promo_name,
            d2.d_year,
            hd2.hd_income_band_sk,
            ib2.ib_lower_bound,
            ib2.ib_upper_bound,
            ca2.ca_state,
            r2.r_reason_desc,
            s.s_store_name,
            inv2.total_qty
        FROM store_sales ss
        JOIN store_returns sr
            ON sr.sr_ticket_number = ss.ss_ticket_number
        JOIN item i2
            ON ss.ss_item_sk = i2.i_item_sk
        JOIN promotion p2
            ON ss.ss_promo_sk = p2.p_promo_sk
        JOIN date_dim d2
            ON ss.ss_sold_date_sk = d2.d_date_sk
        JOIN household_demographics hd2
            ON ss.ss_hdemo_sk = hd2.hd_demo_sk
        JOIN income_band ib2
            ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
        JOIN customer_address ca2
            ON ss.ss_addr_sk = ca2.ca_address_sk
        JOIN reason r2
            ON sr.sr_reason_sk = r2.r_reason_sk
        JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        LEFT JOIN inventory_agg inv2
            ON inv2.inv_item_sk = i2.i_item_sk
        WHERE ss.ss_item_sk IN (SELECT item_sk FROM common_items)
    ),
    -- Union the two streams (deduplication occurs automatically with UNION DISTINCT)
    unified AS (
        SELECT
            i_category      AS category,
            d_year          AS year,
            cs_net_paid     AS net_paid,
            total_qty
        FROM catalog_joined
        UNION DISTINCT
        SELECT
            i_category      AS category,
            d_year          AS year,
            ss_net_paid     AS net_paid,
            total_qty
        FROM store_joined
    ),
    -- Aggregate per category / year and filter with HAVING
    agg AS (
        SELECT
            category,
            year,
            SUM(net_paid)  AS total_net_paid,
            SUM(total_qty) AS total_qty
        FROM unified
        GROUP BY category, year
        HAVING SUM(total_qty) > 1000
    ),
    -- Rank categories and keep top‑5 per category
    ranked AS (
        SELECT
            category,
            year,
            total_net_paid,
            total_qty,
            ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_net_paid DESC) AS rnk
        FROM agg
    )
SELECT
    category,
    year,
    total_net_paid,
    total_qty
FROM ranked
WHERE rnk <= 5
ORDER BY total_net_paid DESC
LIMIT 100

WITH inv_agg AS (
    SELECT
        inv.inv_warehouse_sk,
        inv.inv_date_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk, inv.inv_date_sk
)
SELECT
    d.d_year,
    w.w_warehouse_id,
    w.w_county,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
    SUM(ws.ws_ext_sales_price) AS web_sales_amount,
    inv_agg.total_inventory_qty,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers
FROM
    catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN inv_agg ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
        AND inv_agg.inv_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND w.w_county = 'Mobile County'
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
    AND c.c_birth_month IN (5, 7, 9)
    AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
          AND ws2.ws_sold_date_sk = d.d_date_sk
          AND ws2.ws_ext_discount_amt > 0
    )
GROUP BY
    d.d_year,
    w.w_warehouse_id,
    w.w_county,
    inv_agg.total_inventory_qty
HAVING
    SUM(cs.cs_ext_sales_price) > 10000
ORDER BY
    catalog_sales_amount DESC,
    web_sales_amount DESC
LIMIT 100

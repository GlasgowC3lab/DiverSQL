WITH detail AS (
    SELECT
        d.d_year,
        sm.sm_type,
        cs.cs_ext_sales_price   AS catalog_sales,
        ws.ws_ext_sales_price   AS web_sales,
        sr.sr_return_amt        AS store_return,
        wr.wr_return_amt        AS web_return,
        cs.cs_net_profit        AS catalog_profit,
        ws.ws_net_profit        AS web_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_return_time_sk = t.t_time_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r_store ON sr.sr_reason_sk = r_store.r_reason_sk
    JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
    WHERE d.d_year = 2001
      AND c.c_birth_country = 'United States'
      AND hd.hd_vehicle_count >= 2
      AND w.w_warehouse_sq_ft BETWEEN 500000 AND 800000
      AND sm.sm_type = 'AIR'
      AND ca.ca_location_type = 'single family'
)
SELECT
    COALESCE(d_year, -1) AS year,
    sm_type,
    SUM(catalog_sales)   AS total_catalog_sales,
    SUM(web_sales)       AS total_web_sales,
    SUM(store_return)    AS total_store_return,
    SUM(web_return)      AS total_web_return,
    (SUM(catalog_profit) + SUM(web_profit) - SUM(store_return) - SUM(web_return)) AS net_profit
FROM detail
GROUP BY GROUPING SETS (
    (d_year, sm_type),
    (d_year),
    (sm_type),
    ()
)
ORDER BY year ASC NULLS LAST,
         sm_type ASC NULLS LAST

WITH date_store AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        s.s_store_name,
        s.s_store_id
    FROM date_dim d
    FULL OUTER JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    ds.d_year,
    cd.cd_marital_status,
    sm.sm_type,
    cc.cc_name,
    ds.s_store_name,
    COUNT(DISTINCT cs.cs_order_number)            AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number)            AS web_orders,
    SUM(cs.cs_net_profit)                         AS total_catalog_profit,
    SUM(ws.ws_net_profit)                         AS total_web_profit,
    SUM(cr.cr_net_loss)                           AS total_catalog_return_loss,
    SUM(wr.wr_net_loss)                           AS total_web_return_loss,
    MIN(cs.cs_quantity)                           AS min_catalog_quantity,
    MAX(cs.cs_quantity)                           AS max_catalog_quantity
FROM date_store ds
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = ds.d_date_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = ds.d_date_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_returned_date_sk = ds.d_date_sk
LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = ds.d_date_sk
   AND ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_returned_date_sk = ds.d_date_sk
WHERE cd.cd_marital_status = 'M'
  AND sm.sm_type = 'AIR'
  AND hd.hd_income_band_sk = 2
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
          AND ws2.ws_net_paid > 500
      )
GROUP BY
    ds.d_year,
    cd.cd_marital_status,
    sm.sm_type,
    cc.cc_name,
    ds.s_store_name
ORDER BY (total_catalog_profit + total_web_profit) DESC
LIMIT 100

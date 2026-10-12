WITH page_tokens AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_type,
        token
    FROM catalog_page cp
    CROSS JOIN UNNEST(split(cp.cp_description, ' ')) AS t(token)
)
SELECT
    cp.cp_catalog_page_id,
    sm.sm_type,
    td_s.t_hour AS sale_hour,
    td_r.t_hour AS return_hour,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    SUM(ws.ws_ext_sales_price) AS web_sales,
    SUM(wr.wr_return_amt) AS web_returns,
    COUNT(DISTINCT cs.cs_order_number) AS num_catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS num_web_orders
FROM catalog_sales cs
JOIN page_tokens cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td_s
    ON cs.cs_sold_time_sk = td_s.t_time_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN ship_mode sm_ret
    ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
JOIN time_dim td_r
    ON cr.cr_returned_time_sk = td_r.t_time_sk
JOIN web_sales ws
    ON ws.ws_order_number = cs.cs_order_number
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN time_dim td_ws
    ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
JOIN time_dim td_wr
    ON wr.wr_returned_time_sk = td_wr.t_time_sk
WHERE cp.cp_type = 'monthly'
  AND td_s.t_hour BETWEEN 8 AND 20
GROUP BY
    cp.cp_catalog_page_id,
    sm.sm_type,
    td_s.t_hour,
    td_r.t_hour
ORDER BY total_sales DESC
LIMIT 100

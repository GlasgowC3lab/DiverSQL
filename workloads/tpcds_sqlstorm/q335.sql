WITH sales_union AS (
    SELECT ss_sold_date_sk AS sold_date_sk,
           ss_store_sk AS location_sk,
           ss_item_sk AS item_sk,
           ss_net_paid AS net_paid,
           ss_net_profit AS net_profit,
           ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk AS sold_date_sk,
           cs_call_center_sk AS location_sk,
           cs_item_sk AS item_sk,
           cs_net_paid AS net_paid,
           cs_net_profit AS net_profit,
           cs_quantity AS quantity,
           'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk AS sold_date_sk,
           ws_warehouse_sk AS location_sk,
           ws_item_sk AS item_sk,
           ws_net_paid AS net_paid,
           ws_net_profit AS net_profit,
           ws_quantity AS quantity,
           'web' AS channel
    FROM web_sales
)
SELECT d.d_year,
       COALESCE(st.s_state, cc.cc_state, w.w_state) AS region,
       s.channel,
       SUM(s.net_paid) AS total_paid,
       SUM(s.net_profit) AS total_profit,
       SUM(s.quantity) AS total_quantity
FROM sales_union s
LEFT JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
LEFT JOIN store st ON s.channel = 'store' AND s.location_sk = st.s_store_sk
LEFT JOIN call_center cc ON s.channel = 'catalog' AND s.location_sk = cc.cc_call_center_sk
LEFT JOIN warehouse w ON s.channel = 'web' AND s.location_sk = w.w_warehouse_sk
GROUP BY d.d_year, COALESCE(st.s_state, cc.cc_state, w.w_state), s.channel
ORDER BY d.d_year, region, s.channel
LIMIT 100

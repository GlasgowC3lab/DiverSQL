WITH sales_union AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_store_sk AS store_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    UNION ALL
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_call_center_sk AS store_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT ws.ws_sold_date_sk AS date_sk,
           ws.ws_ship_mode_sk AS store_sk,
           ws.ws_item_sk AS item_sk,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
)
SELECT
    d.d_year,
    COALESCE(s.s_store_name, cc.cc_name, sm.sm_type) AS channel_name,
    i.i_product_name,
    SUM(su.net_paid) AS total_net_paid,
    SUM(su.net_profit) AS total_net_profit,
    COUNT(*) AS sales_cnt
FROM sales_union su
JOIN date_dim d ON su.date_sk = d.d_date_sk
LEFT JOIN store s ON su.store_sk = s.s_store_sk
LEFT JOIN call_center cc ON su.store_sk = cc.cc_call_center_sk
LEFT JOIN ship_mode sm ON su.store_sk = sm.sm_ship_mode_sk
JOIN item i ON su.item_sk = i.i_item_sk
WHERE d.d_year = 2001
  AND i.i_category = 'Sports'
GROUP BY d.d_year,
         COALESCE(s.s_store_name, cc.cc_name, sm.sm_type),
         i.i_product_name
ORDER BY total_net_paid DESC
LIMIT 100

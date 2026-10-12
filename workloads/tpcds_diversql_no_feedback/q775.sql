WITH filtered_sales AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_profit,
    i.i_brand,
    i.i_item_desc,
    sm.sm_carrier,
    t.t_sub_shift,
    wp.wp_url
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE regexp_like(i.i_item_desc, '[0-9]{3}')
    AND wp.wp_url LIKE '%/home/%'
    AND t.t_sub_shift = 'morning'
)
SELECT
  sm_carrier,
  COUNT(DISTINCT ws_order_number) AS orders,
  SUM(ws_net_profit) AS total_profit,
  REGEXP_EXTRACT(i_item_desc, '([A-Z]{2,})') AS extracted_code,
  CONCAT(i_brand, ' - ', i_item_desc) AS brand_item
FROM filtered_sales
GROUP BY
  sm_carrier,
  REGEXP_EXTRACT(i_item_desc, '([A-Z]{2,})'),
  CONCAT(i_brand, ' - ', i_item_desc)
ORDER BY total_profit DESC
LIMIT 100

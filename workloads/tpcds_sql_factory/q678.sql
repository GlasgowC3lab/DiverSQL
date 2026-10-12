WITH city_channel_profit AS (
  SELECT
    ca.ca_city,
    p.p_channel_tv,
    SUM(ws.ws_net_profit) AS city_channel_profit,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN ws.ws_ext_discount_amt ELSE 0 END) AS total_active_discount,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(DISTINCT cd.cd_demo_sk) AS distinct_demo_count,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS discount_status
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  GROUP BY ca.ca_city, p.p_channel_tv, p.p_discount_active
)
SELECT
  ca_city,
  p_channel_tv,
  city_channel_profit,
  orders,
  avg_sales_price,
  total_active_discount,
  avg_purchase_estimate,
  distinct_demo_count,
  discount_status,
  DENSE_RANK() OVER (PARTITION BY ca_city ORDER BY city_channel_profit DESC) AS channel_rank_in_city,
  CASE WHEN total_active_discount > 0 THEN 'Has Discount' ELSE 'No Discount' END AS discount_flag
FROM city_channel_profit
WHERE city_channel_profit IS NOT NULL
ORDER BY city_channel_profit DESC
LIMIT 20

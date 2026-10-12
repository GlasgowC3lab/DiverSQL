WITH sales_union AS (
  SELECT
    'store' AS channel,
    ss.ss_sold_date_sk AS sold_date_sk,
    ss.ss_item_sk AS item_sk,
    ss.ss_store_sk AS store_sk,
    ss.ss_promo_sk AS promo_sk,
    ss.ss_customer_sk AS customer_sk,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    ss.ss_sales_price AS sales_price,
    ss.ss_quantity AS quantity,
    s.s_state AS state
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE ss.ss_sold_date_sk IS NOT NULL

  UNION ALL

  SELECT
    'web' AS channel,
    ws.ws_sold_date_sk AS sold_date_sk,
    ws.ws_item_sk AS item_sk,
    NULL AS store_sk,
    ws.ws_promo_sk AS promo_sk,
    ws.ws_bill_customer_sk AS customer_sk,
    ws.ws_net_paid AS net_paid,
    ws.ws_net_profit AS net_profit,
    ws.ws_sales_price AS sales_price,
    ws.ws_quantity AS quantity,
    we.web_state AS state
  FROM web_sales ws
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  WHERE ws.ws_sold_date_sk IS NOT NULL

  UNION ALL

  SELECT
    'catalog' AS channel,
    cs.cs_sold_date_sk AS sold_date_sk,
    cs.cs_item_sk AS item_sk,
    NULL AS store_sk,
    cs.cs_promo_sk AS promo_sk,
    cs.cs_bill_customer_sk AS customer_sk,
    cs.cs_net_paid AS net_paid,
    cs.cs_net_profit AS net_profit,
    cs.cs_sales_price AS sales_price,
    cs.cs_quantity AS quantity,
    cc.cc_state AS state
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE cs.cs_sold_date_sk IS NOT NULL
)
SELECT
  su.channel,
  d.d_year,
  i.i_category,
  su.state,
  SUM(su.net_paid) AS total_net_paid,
  SUM(su.net_profit) AS total_net_profit,
  AVG(su.sales_price) AS avg_sales_price,
  COUNT(DISTINCT su.customer_sk) AS distinct_customers,
  SUM(su.quantity) AS total_quantity
FROM sales_union su
JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
JOIN item i ON su.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY su.channel, d.d_year, i.i_category, su.state
ORDER BY total_net_paid DESC
LIMIT 100

WITH unified_sales AS (
  SELECT
    cs.cs_promo_sk AS promo_sk,
    cs.cs_order_number AS order_number,
    cs.cs_quantity AS quantity,
    cs.cs_net_paid AS net_paid,
    cs.cs_ext_discount_amt AS discount_amt,
    'catalog' AS channel
  FROM catalog_sales cs
  WHERE cs.cs_wholesale_cost > 50
  UNION ALL
  SELECT
    ws.ws_promo_sk AS promo_sk,
    ws.ws_order_number AS order_number,
    ws.ws_quantity AS quantity,
    ws.ws_net_paid AS net_paid,
    ws.ws_ext_discount_amt AS discount_amt,
    'web' AS channel
  FROM web_sales ws
  WHERE ws.ws_wholesale_cost > 50
),
promo_agg AS (
  SELECT
    p.p_promo_name,
    SUM(CASE WHEN us.channel = 'catalog' THEN us.net_paid ELSE 0 END) AS catalog_net_paid,
    SUM(CASE WHEN us.channel = 'web' THEN us.net_paid ELSE 0 END) AS web_net_paid,
    SUM(us.net_paid) AS total_net_paid,
    COUNT(DISTINCT CASE WHEN us.channel = 'catalog' THEN us.order_number END) AS catalog_orders,
    COUNT(DISTINCT CASE WHEN us.channel = 'web' THEN us.order_number END) AS web_orders,
    SUM(us.quantity) AS total_quantity,
    AVG(us.discount_amt) AS avg_discount_per_order
  FROM promotion p
  JOIN unified_sales us ON us.promo_sk = p.p_promo_sk
  WHERE p.p_discount_active = 'Y'
  GROUP BY p.p_promo_name
  HAVING SUM(us.net_paid) > 100000
)
SELECT
  pa.p_promo_name,
  pa.catalog_net_paid,
  pa.web_net_paid,
  pa.total_net_paid,
  pa.catalog_orders,
  pa.web_orders,
  pa.total_quantity,
  pa.avg_discount_per_order,
  ROW_NUMBER() OVER (ORDER BY pa.total_net_paid DESC) AS revenue_rank
FROM promo_agg pa
ORDER BY pa.total_net_paid DESC
LIMIT 10

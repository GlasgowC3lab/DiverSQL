WITH combined_sales AS (
  SELECT
    p.p_promo_sk,
    p.p_promo_name,
    cs.cs_item_sk AS item_sk,
    SUM(cs.cs_ext_sales_price) AS revenue
  FROM catalog_sales cs
  INNER JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  GROUP BY p.p_promo_sk, p.p_promo_name, cs.cs_item_sk
  UNION ALL
  SELECT
    p.p_promo_sk,
    p.p_promo_name,
    ws.ws_item_sk AS item_sk,
    SUM(ws.ws_ext_sales_price) AS revenue
  FROM web_sales ws
  INNER JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  GROUP BY p.p_promo_sk, p.p_promo_name, ws.ws_item_sk
),
agg_sales AS (
  SELECT
    p_promo_sk,
    p_promo_name,
    item_sk,
    SUM(revenue) AS total_revenue
  FROM combined_sales
  GROUP BY p_promo_sk, p_promo_name, item_sk
),
ranked_sales AS (
  SELECT
    p_promo_name AS promo_name,
    item_sk,
    total_revenue,
    DENSE_RANK() OVER (PARTITION BY p_promo_name ORDER BY total_revenue DESC) AS revenue_rank
  FROM agg_sales
)
SELECT
  promo_name,
  item_sk,
  total_revenue,
  revenue_rank
FROM ranked_sales
WHERE revenue_rank <= 5
ORDER BY promo_name, revenue_rank

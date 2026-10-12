WITH unified_sales AS (
  SELECT
    cs.cs_sold_date_sk AS date_sk,
    cs.cs_item_sk AS item_sk,
    cs.cs_call_center_sk AS location_sk,
    cs.cs_promo_sk AS promo_sk,
    cs.cs_quantity AS quantity,
    cs.cs_net_paid AS net_paid,
    cs.cs_net_profit AS net_profit,
    'catalog' AS channel
  FROM catalog_sales cs
  UNION ALL
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_item_sk,
    ss.ss_store_sk,
    ss.ss_promo_sk,
    ss.ss_quantity,
    ss.ss_net_paid,
    ss.ss_net_profit,
    'store' AS channel
  FROM store_sales ss
  UNION ALL
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_item_sk,
    ws.ws_warehouse_sk,
    ws.ws_promo_sk,
    ws.ws_quantity,
    ws.ws_net_paid,
    ws.ws_net_profit,
    'web' AS channel
  FROM web_sales ws
),
monthly_category_sales AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_class,
    i.i_brand,
    s.channel,
    SUM(s.quantity) AS total_quantity,
    SUM(s.net_paid) AS total_net_paid,
    SUM(s.net_profit) AS total_net_profit,
    COUNT(DISTINCT s.item_sk) AS distinct_items_sold,
    approx_percentile(s.net_paid, 0.5) AS median_net_paid,
    AVG(s.net_paid) AS avg_net_paid,
    MIN(pr.p_promo_name) AS promo_name,
    MIN(COALESCE(st.s_store_name, cc.cc_name, wh.w_warehouse_name)) AS location_name,
    s.location_sk
  FROM unified_sales s
  LEFT JOIN date_dim d ON s.date_sk = d.d_date_sk
  LEFT JOIN item i ON s.item_sk = i.i_item_sk
  LEFT JOIN promotion pr ON s.promo_sk = pr.p_promo_sk
  LEFT JOIN store st ON s.channel = 'store' AND s.location_sk = st.s_store_sk
  LEFT JOIN call_center cc ON s.channel = 'catalog' AND s.location_sk = cc.cc_call_center_sk
  LEFT JOIN warehouse wh ON s.channel = 'web' AND s.location_sk = wh.w_warehouse_sk
  GROUP BY
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_class,
    i.i_brand,
    s.channel,
    s.location_sk
  HAVING SUM(s.net_paid) > 100000
),
ranked_monthly AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY i_category, channel ORDER BY d_year, d_month_seq) AS month_seq,
    LAG(total_net_paid) OVER (PARTITION BY i_category, channel ORDER BY d_year, d_month_seq) AS prev_month_net_paid
  FROM monthly_category_sales
)
SELECT
  d_year,
  d_month_seq,
  i_category,
  i_class,
  i_brand,
  channel,
  total_quantity,
  total_net_paid,
  total_net_profit,
  distinct_items_sold,
  median_net_paid,
  avg_net_paid,
  promo_name,
  location_name,
  CASE
    WHEN prev_month_net_paid IS NULL OR prev_month_net_paid = 0 THEN NULL
    ELSE (total_net_paid - prev_month_net_paid) / prev_month_net_paid * 100
  END AS mom_growth_pct,
  ROW_NUMBER() OVER (PARTITION BY i_category, d_year ORDER BY total_net_profit DESC) AS profit_rank_in_year
FROM ranked_monthly
ORDER BY d_year, d_month_seq, total_net_paid DESC
LIMIT 200

WITH dr AS (
  SELECT d_date_sk, d_date, d_year
  FROM date_dim
  WHERE d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
),
catalog_daily AS (
  SELECT dr.d_date_sk, dr.d_date, dr.d_year,
         'catalog' AS channel,
         COALESCE(SUM(cs.cs_net_paid),0) AS net_paid,
         COALESCE(SUM(cs.cs_net_profit),0) AS net_profit,
         COUNT(DISTINCT cs.cs_order_number) AS orders,
         COALESCE(SUM(cs.cs_quantity),0) AS total_quantity,
         ROW_NUMBER() OVER (PARTITION BY dr.d_year ORDER BY COALESCE(SUM(cs.cs_net_paid),0) DESC) AS rank_year
  FROM dr
  LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = dr.d_date_sk
  GROUP BY dr.d_date_sk, dr.d_date, dr.d_year
),
store_daily AS (
  SELECT dr.d_date_sk, dr.d_date, dr.d_year,
         'store' AS channel,
         COALESCE(SUM(ss.ss_net_paid),0) AS net_paid,
         COALESCE(SUM(ss.ss_net_profit),0) AS net_profit,
         COUNT(DISTINCT ss.ss_ticket_number) AS orders,
         COALESCE(SUM(ss.ss_quantity),0) AS total_quantity,
         ROW_NUMBER() OVER (PARTITION BY dr.d_year ORDER BY COALESCE(SUM(ss.ss_net_paid),0) DESC) AS rank_year
  FROM dr
  LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = dr.d_date_sk
  GROUP BY dr.d_date_sk, dr.d_date, dr.d_year
),
web_daily AS (
  SELECT dr.d_date_sk, dr.d_date, dr.d_year,
         'web' AS channel,
         COALESCE(SUM(ws.ws_net_paid),0) AS net_paid,
         COALESCE(SUM(ws.ws_net_profit),0) AS net_profit,
         COUNT(DISTINCT ws.ws_order_number) AS orders,
         COALESCE(SUM(ws.ws_quantity),0) AS total_quantity,
         ROW_NUMBER() OVER (PARTITION BY dr.d_year ORDER BY COALESCE(SUM(ws.ws_net_paid),0) DESC) AS rank_year
  FROM dr
  LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = dr.d_date_sk
  GROUP BY dr.d_date_sk, dr.d_date, dr.d_year
),
combined_sales AS (
  SELECT * FROM catalog_daily
  UNION ALL
  SELECT * FROM store_daily
  UNION ALL
  SELECT * FROM web_daily
),
catalog_returns_agg AS (
  SELECT cr_returned_date_sk AS d_date_sk, SUM(cr_net_loss) AS catalog_net_loss
  FROM catalog_returns
  GROUP BY cr_returned_date_sk
),
store_returns_agg AS (
  SELECT sr_returned_date_sk AS d_date_sk, SUM(sr_net_loss) AS store_net_loss
  FROM store_returns
  GROUP BY sr_returned_date_sk
),
web_returns_agg AS (
  SELECT wr_returned_date_sk AS d_date_sk, SUM(wr_net_loss) AS web_net_loss
  FROM web_returns
  GROUP BY wr_returned_date_sk
),
returns_summary AS (
  SELECT dr.d_date_sk,
         COALESCE(c.catalog_net_loss,0) + COALESCE(s.store_net_loss,0) + COALESCE(w.web_net_loss,0) AS total_net_loss
  FROM dr
  LEFT JOIN catalog_returns_agg c ON c.d_date_sk = dr.d_date_sk
  LEFT JOIN store_returns_agg s ON s.d_date_sk = dr.d_date_sk
  LEFT JOIN web_returns_agg w ON w.d_date_sk = dr.d_date_sk
),
joined AS (
  SELECT cs.*, rs.total_net_loss
  FROM combined_sales cs
  LEFT JOIN returns_summary rs ON rs.d_date_sk = cs.d_date_sk
),
final AS (
  SELECT
    j.d_date_sk,
    j.d_date,
    j.channel,
    j.net_paid,
    j.net_profit,
    j.orders,
    j.total_quantity,
    j.total_net_loss,
    j.net_paid - j.total_net_loss AS net_contribution,
    CASE
      WHEN j.net_paid IS NULL OR j.total_net_loss IS NULL THEN NULL
      WHEN j.net_paid = 0 THEN 0
      ELSE (j.net_profit - j.total_net_loss) / NULLIF(j.net_paid,0)
    END AS adj_margin,
    CONCAT('ID_', CAST(j.d_date_sk AS VARCHAR), '_', UPPER(j.channel)) AS composite_id,
    ROW_NUMBER() OVER (ORDER BY (j.net_paid - j.total_net_loss) DESC) AS overall_rank,
    RANK() OVER (PARTITION BY j.channel ORDER BY (j.net_paid - j.total_net_loss) DESC) AS channel_rank,
    COALESCE(NULLIF(j.channel, ''), 'UNKNOWN') AS safe_channel,
    CASE
      WHEN (j.net_paid - j.total_net_loss) > 200000 THEN 'PLATINUM'
      WHEN (j.net_paid - j.total_net_loss) > 100000 THEN 'GOLD'
      WHEN (j.net_paid - j.total_net_loss) > 50000 THEN 'SILVER'
      ELSE 'BRONZE'
    END AS tier,
    CASE
      WHEN j.channel = 'catalog' THEN (SELECT COALESCE(MAX(cs_quantity),0) FROM catalog_sales cs WHERE cs.cs_sold_date_sk = j.d_date_sk)
      WHEN j.channel = 'store' THEN (SELECT COALESCE(MAX(ss_quantity),0) FROM store_sales ss WHERE ss.ss_sold_date_sk = j.d_date_sk)
      ELSE (SELECT COALESCE(MAX(ws_quantity),0) FROM web_sales ws WHERE ws.ws_sold_date_sk = j.d_date_sk)
    END AS max_quantity,
    CASE
      WHEN j.channel = 'catalog' THEN (SELECT COUNT(DISTINCT cs_item_sk) FROM catalog_sales cs WHERE cs.cs_sold_date_sk = j.d_date_sk)
      WHEN j.channel = 'store' THEN (SELECT COUNT(DISTINCT ss_item_sk) FROM store_sales ss WHERE ss.ss_sold_date_sk = j.d_date_sk)
      ELSE (SELECT COUNT(DISTINCT ws_item_sk) FROM web_sales ws WHERE ws.ws_sold_date_sk = j.d_date_sk)
    END AS distinct_items,
    CASE
      WHEN REGEXP_LIKE(j.channel, '^c') THEN REGEXP_REPLACE(j.channel, 'c', 'C')
      ELSE j.channel
    END AS channel_tag
  FROM joined j
)
SELECT
  composite_id,
  d_date,
  channel,
  net_paid,
  net_profit,
  orders,
  total_quantity,
  total_net_loss,
  net_contribution,
  CAST(ROUND(adj_margin * 100, 2) AS VARCHAR) || '%' AS adj_margin_pct,
  overall_rank,
  channel_rank,
  tier,
  safe_channel,
  max_quantity,
  distinct_items,
  channel_tag,
  CASE
    WHEN net_contribution IS NULL THEN 'UNKNOWN'
    WHEN net_contribution = 0 THEN 'ZERO'
    WHEN net_contribution > 0 THEN 'POSITIVE'
    ELSE 'NEGATIVE'
  END AS contribution_status
FROM final
WHERE (channel = 'catalog' AND net_paid > 150000)
   OR (channel = 'store' AND net_profit > 50000)
   OR (channel = 'web' AND max_quantity > 5)
ORDER BY overall_rank
LIMIT 100

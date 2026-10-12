WITH store_agg AS (
  SELECT
    p.p_promo_id,
    p.p_promo_name,
    d.d_year,
    d.d_month_seq,
    SUM(ss.ss_net_profit) AS store_profit,
    SUM(ss.ss_net_paid) AS store_net_paid
  FROM store_sales ss
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year >= 2020
    AND ss.ss_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
  GROUP BY p.p_promo_id, p.p_promo_name, d.d_year, d.d_month_seq
),
web_agg AS (
  SELECT
    p.p_promo_id,
    p.p_promo_name,
    d_ws.d_year,
    d_ws.d_month_seq,
    SUM(ws.ws_net_profit) AS web_profit,
    SUM(ws.ws_net_paid) AS web_net_paid
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
  WHERE d_ws.d_year >= 2020
    AND ws.ws_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
  GROUP BY p.p_promo_id, p.p_promo_name, d_ws.d_year, d_ws.d_month_seq
)
SELECT
  COALESCE(s.p_promo_id, w.p_promo_id) AS promo_id,
  COALESCE(s.p_promo_name, w.p_promo_name) AS promo_name,
  COALESCE(s.d_year, w.d_year) AS year,
  COALESCE(s.d_month_seq, w.d_month_seq) AS month_seq,
  COALESCE(s.store_profit, 0) AS store_profit,
  COALESCE(w.web_profit, 0) AS web_profit,
  (COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0)) AS total_profit,
  CASE
    WHEN (COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0)) = 0 THEN 0
    ELSE COALESCE(s.store_profit, 0) / (COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0))
  END AS store_profit_ratio
FROM store_agg s
FULL OUTER JOIN web_agg w
  ON s.p_promo_id = w.p_promo_id
  AND s.d_year = w.d_year
  AND s.d_month_seq = w.d_month_seq
WHERE (COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0)) > 0
ORDER BY total_profit DESC
LIMIT 10

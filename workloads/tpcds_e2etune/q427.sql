WITH combined_sales AS (
  SELECT
    ss.ss_promo_sk AS promo_sk,
    td.t_shift AS shift,
    ss.ss_net_profit AS net_profit,
    ss.ss_net_paid AS net_paid,
    ss.ss_ext_discount_amt AS discount,
    1 AS txn_cnt
  FROM store_sales ss
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  UNION ALL
  SELECT
    ws.ws_promo_sk AS promo_sk,
    td.t_shift AS shift,
    ws.ws_net_profit AS net_profit,
    ws.ws_net_paid AS net_paid,
    ws.ws_ext_discount_amt AS discount,
    1 AS txn_cnt
  FROM web_sales ws
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
),
agg_sales AS (
  SELECT
    p.p_promo_id,
    p.p_promo_name,
    cs.shift,
    SUM(cs.net_profit) AS total_net_profit,
    SUM(cs.net_paid) AS total_net_paid,
    SUM(cs.discount) AS total_discount,
    SUM(cs.txn_cnt) AS total_txn_cnt,
    p.p_channel_tv,
    p.p_channel_email
  FROM combined_sales cs
  JOIN promotion p ON cs.promo_sk = p.p_promo_sk
  WHERE p.p_start_date_sk >= 2450906
    AND (p.p_channel_tv = 'Y' OR p.p_channel_email = 'Y')
    AND cs.shift IN ('Evening', 'Night')
  GROUP BY p.p_promo_id, p.p_promo_name, cs.shift, p.p_channel_tv, p.p_channel_email
)
SELECT
  p_promo_id,
  p_promo_name,
  shift,
  total_net_profit,
  total_net_paid,
  CASE WHEN total_txn_cnt = 0 THEN NULL ELSE total_discount / total_txn_cnt END AS overall_avg_discount,
  total_txn_cnt,
  p_channel_tv,
  p_channel_email,
  RANK() OVER (PARTITION BY shift ORDER BY total_net_profit DESC) AS profit_rank
FROM agg_sales
ORDER BY total_net_profit DESC
LIMIT 100

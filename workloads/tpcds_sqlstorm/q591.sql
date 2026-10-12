WITH agg AS (
  SELECT
    s.s_store_name,
    i.i_category,
    CASE
      WHEN p.p_channel_tv = 'Y' THEN 'TV'
      WHEN p.p_channel_radio = 'Y' THEN 'Radio'
      WHEN p.p_channel_email = 'Y' THEN 'Email'
      ELSE 'Other'
    END AS promo_channel,
    d.d_year,
    SUM(ss.ss_net_profit) AS total_profit
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 1998
  GROUP BY
    s.s_store_name,
    i.i_category,
    CASE
      WHEN p.p_channel_tv = 'Y' THEN 'TV'
      WHEN p.p_channel_radio = 'Y' THEN 'Radio'
      WHEN p.p_channel_email = 'Y' THEN 'Email'
      ELSE 'Other'
    END,
    d.d_year
)
SELECT
  s_store_name,
  i_category,
  promo_channel,
  d_year,
  total_profit,
  RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY d_year, profit_rank
LIMIT 100

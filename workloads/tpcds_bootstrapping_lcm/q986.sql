WITH aggregated AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    s.s_geography_class,
    hd_ref.hd_buy_potential,
    p.p_channel_tv,
    p.p_discount_active,
    date_diff('day', d.d_date, d_end.d_date) AS promo_duration_days,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(p.p_cost) AS avg_promo_cost,
    COUNT(DISTINCT hd_ref.hd_demo_sk) AS distinct_refunded_households,
    COUNT(*) AS return_rows
  FROM date_dim d
  JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN household_demographics hd_ret ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
  JOIN store s ON s.s_closed_date_sk = d.d_date_sk
  JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
  JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
  GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_geography_class,
    hd_ref.hd_buy_potential,
    p.p_channel_tv,
    p.p_discount_active,
    date_diff('day', d.d_date, d_end.d_date)
)
SELECT
  a.d_year,
  a.d_month_seq,
  a.s_geography_class,
  a.hd_buy_potential,
  a.p_channel_tv,
  a.p_discount_active,
  a.promo_duration_days,
  a.total_return_amt,
  a.total_net_loss,
  a.avg_promo_cost,
  a.distinct_refunded_households,
  a.return_rows,
  CASE WHEN a.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Full Price' END AS promo_type,
  RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_net_loss DESC) AS net_loss_rank
FROM aggregated a
ORDER BY a.d_year, a.total_net_loss DESC
LIMIT 100

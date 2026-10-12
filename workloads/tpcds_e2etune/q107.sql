WITH sales_agg AS (
  SELECT
    ss.ss_store_sk,
    ss.ss_hdemo_sk,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
  FROM store_sales ss
  GROUP BY ss.ss_store_sk, ss.ss_hdemo_sk
),
returns_agg AS (
  SELECT
    sr.sr_store_sk,
    sr.sr_hdemo_sk,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_tickets
  FROM store_returns sr
  GROUP BY sr.sr_store_sk, sr.sr_hdemo_sk
),
joined AS (
  SELECT
    s.s_store_name,
    s.s_state,
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    sa.total_net_profit,
    ra.total_return_amount,
    ra.total_net_loss,
    (sa.total_net_profit - COALESCE(ra.total_net_loss, 0)) AS net_profit_after_returns,
    sa.total_quantity,
    sa.total_sales
  FROM sales_agg sa
  LEFT JOIN returns_agg ra
    ON sa.ss_store_sk = ra.sr_store_sk
   AND sa.ss_hdemo_sk = ra.sr_hdemo_sk
  JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
  JOIN household_demographics hd
    ON sa.ss_hdemo_sk = hd.hd_demo_sk
  WHERE s.s_state = 'CA'
    AND hd.hd_income_band_sk >= 4
    AND hd.hd_buy_potential IN ('1001-5000', '5001-10000', '>10000')
)
SELECT
  s_store_name,
  s_state,
  hd_income_band_sk,
  hd_buy_potential,
  net_profit_after_returns,
  total_sales,
  total_quantity,
  RANK() OVER (PARTITION BY s_state ORDER BY net_profit_after_returns DESC) AS profit_rank_state
FROM joined
ORDER BY net_profit_after_returns DESC
LIMIT 100

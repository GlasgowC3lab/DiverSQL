WITH base AS (
  SELECT
    cr.cr_returning_hdemo_sk,
    cr.cr_refunded_hdemo_sk,
    cr.cr_call_center_sk,
    cr.cr_return_tax,
    cr.cr_return_amount,
    cr.cr_order_number,
    cc.cc_name,
    cc.cc_rec_start_date,
    rc.hd_income_band_sk AS returning_income_band,
    rc.hd_buy_potential AS returning_buy_potential,
    rd.hd_income_band_sk AS refunded_income_band,
    rd.hd_buy_potential AS refunded_buy_potential,
    split(cc.cc_hours, ',') AS hours_array
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN household_demographics rc ON cr.cr_returning_hdemo_sk = rc.hd_demo_sk
  JOIN household_demographics rd ON cr.cr_refunded_hdemo_sk = rd.hd_demo_sk
  WHERE cc.cc_rec_start_date >= DATE '2000-01-01'
    AND cc.cc_country = 'United States'
    AND cr.cr_return_tax > 10
),
exploded AS (
  SELECT
    b.*,
    h AS hour_part
  FROM base b
  CROSS JOIN UNNEST(b.hours_array) AS t(h)
),
agg1 AS (
  SELECT
    hour_part,
    COUNT(*) AS cnt_returns,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_tax) AS avg_return_tax
  FROM exploded
  GROUP BY hour_part
)
SELECT
  hour_part,
  cnt_returns,
  total_return_amount,
  avg_return_tax,
  cnt_returns * avg_return_tax AS weighted_metric
FROM agg1
WHERE cnt_returns > 5
ORDER BY total_return_amount DESC
LIMIT 100

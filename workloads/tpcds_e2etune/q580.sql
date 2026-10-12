WITH return_agg AS (
  SELECT
    cr_ret.cd_marital_status AS returning_marital_status,
    cr_ret.cd_gender AS returning_gender,
    cr_ref.cd_marital_status AS refunded_marital_status,
    cr_ref.cd_gender AS refunded_gender,
    wp.wp_type AS page_type,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
    SUM(wr.wr_fee) AS total_fee,
    AVG(wr.wr_net_loss) AS avg_net_loss,
    COUNT(*) AS return_cnt
  FROM web_returns wr
  JOIN customer_demographics cr_ret
    ON wr.wr_returning_cdemo_sk = cr_ret.cd_demo_sk
  JOIN customer_demographics cr_ref
    ON wr.wr_refunded_cdemo_sk = cr_ref.cd_demo_sk
  JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
  JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE wr.wr_returned_date_sk >= 2450800
    AND wr.wr_return_amt_inc_tax > 0
    AND hd_ret.hd_vehicle_count >= 2
    AND hd_ref.hd_income_band_sk IN (3, 4, 5)
    AND wp.wp_type IS NOT NULL
  GROUP BY
    cr_ret.cd_marital_status,
    cr_ret.cd_gender,
    cr_ref.cd_marital_status,
    cr_ref.cd_gender,
    wp.wp_type
)
SELECT
  ra.returning_marital_status,
  ra.returning_gender,
  ra.refunded_marital_status,
  ra.refunded_gender,
  ra.page_type,
  ra.total_return_amount,
  ra.total_fee,
  ra.avg_net_loss,
  ra.return_cnt,
  CASE
    WHEN ra.total_return_amount >= 10000 THEN 'High'
    WHEN ra.total_return_amount >= 5000 THEN 'Medium'
    ELSE 'Low'
  END AS amount_bucket,
  RANK() OVER (ORDER BY ra.total_return_amount DESC) AS amount_rank
FROM return_agg ra
ORDER BY ra.total_return_amount DESC
LIMIT 10

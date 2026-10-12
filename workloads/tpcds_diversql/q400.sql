WITH base AS (
  SELECT
    sr.sr_returned_date_sk,
    sr.sr_cdemo_sk,
    sr.sr_return_amt_inc_tax,
    sr.sr_refunded_cash,
    d.d_year,
    d.d_quarter_name,
    cd.cd_gender,
    cd.cd_education_status,
    p.p_channel_press
  FROM store_returns sr
  JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
  WHERE d.d_year = 1910
    AND cd.cd_gender = 'F'
    AND cd.cd_education_status = 'College'
    AND p.p_channel_press = 'N'
    AND sr.sr_return_amt_inc_tax > 100
),
agg1 AS (
  SELECT
    d_year,
    cd_gender,
    SUM(sr_return_amt_inc_tax) AS sum_amt,
    COUNT(*) AS return_cnt,
    AVG(sr_refunded_cash) AS avg_refund
  FROM base
  GROUP BY d_year, cd_gender
),
agg1_final AS (
  SELECT
    d_year,
    cd_gender,
    CASE WHEN sum_amt > 1000 THEN 'High' ELSE 'Low' END AS return_category,
    return_cnt,
    sum_amt AS total_return_amt,
    avg_refund AS avg_refund_cash
  FROM agg1
),
agg2 AS (
  SELECT
    d_year,
    cd_gender,
    SUM(sr_return_amt_inc_tax) AS sum_amt,
    COUNT(*) AS return_cnt,
    AVG(sr_refunded_cash) AS avg_refund
  FROM base
  WHERE sr_return_amt_inc_tax BETWEEN 200 AND 500
  GROUP BY d_year, cd_gender
),
agg2_final AS (
  SELECT
    d_year,
    cd_gender,
    CASE WHEN sum_amt > 500 THEN 'Medium' ELSE 'Low' END AS return_category,
    return_cnt,
    sum_amt AS total_return_amt,
    avg_refund AS avg_refund_cash
  FROM agg2
),
unioned AS (
  SELECT d_year, cd_gender, return_category, return_cnt, total_return_amt, avg_refund_cash FROM agg1_final
  UNION
  SELECT d_year, cd_gender, return_category, return_cnt, total_return_amt, avg_refund_cash FROM agg2_final
),
final AS (
  SELECT
    d_year,
    cd_gender,
    return_category,
    SUM(return_cnt) AS total_cnt,
    SUM(total_return_amt) AS grand_total_return_amt,
    AVG(avg_refund_cash) AS avg_refund_cash_overall
  FROM unioned
  GROUP BY d_year, cd_gender, return_category
)
SELECT
  f.d_year,
  f.cd_gender,
  f.return_category,
  f.total_cnt,
  f.grand_total_return_amt,
  f.avg_refund_cash_overall,
  q.d_quarter_name
FROM final f
CROSS JOIN (
  SELECT DISTINCT d_quarter_name
  FROM date_dim
  WHERE d_quarter_name IN ('1904Q1', '1904Q3')
) q
ORDER BY f.d_year DESC, f.total_cnt DESC
LIMIT 100

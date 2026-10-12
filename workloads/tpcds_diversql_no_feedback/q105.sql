WITH filtered_returns AS (
  SELECT
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_net_loss,
    cr.cr_reason_sk,
    cr.cr_refunded_cdemo_sk,
    cr.cr_refunded_hdemo_sk,
    cr.cr_order_number
  FROM catalog_returns cr
  WHERE cr.cr_return_quantity > 1
    AND cr.cr_return_amount > 100.00
    AND cr.cr_reason_sk IN (
      SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%damaged%'
    )
),
joined AS (
  SELECT
    cr.cr_net_loss,
    cr.cr_reason_sk,
    r.r_reason_desc,
    cd.cd_gender,
    cd.cd_credit_rating,
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    cs.cs_ext_ship_cost
  FROM filtered_returns cr
  JOIN catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
  JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  WHERE cs.cs_ext_ship_cost BETWEEN 500 AND 2000
    AND cd.cd_credit_rating = 'Good'
    AND hd.hd_buy_potential = '1001-5000'
),
agg AS (
  SELECT
    j.r_reason_desc,
    j.cd_gender,
    j.hd_income_band_sk,
    SUM(j.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count
  FROM joined j
  GROUP BY
    j.r_reason_desc,
    j.cd_gender,
    j.hd_income_band_sk
)
SELECT
  a.r_reason_desc,
  a.cd_gender,
  a.hd_income_band_sk,
  a.total_net_loss,
  a.return_count,
  RANK() OVER (PARTITION BY a.cd_gender ORDER BY a.total_net_loss DESC) AS gender_rank
FROM agg a
ORDER BY a.total_net_loss DESC
LIMIT 100

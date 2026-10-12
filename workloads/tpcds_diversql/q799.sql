WITH
  hd_ref AS (
    SELECT hd_demo_sk, hd_income_band_sk, hd_buy_potential, hd_dep_count, hd_vehicle_count
    FROM household_demographics
  ),
  hd_ret AS (
    SELECT hd_demo_sk, hd_income_band_sk,
           hd_buy_potential AS ret_buy_potential,
           hd_dep_count AS ret_dep_count,
           hd_vehicle_count AS ret_vehicle_count
    FROM household_demographics
  ),
  ib_ref AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
  ),
  ib_ret AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
  ),
  r AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
  ),
  r_alt AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
    WHERE r_reason_desc LIKE '%damaged%'
  ),
  t_ret AS (
    SELECT t_time_sk, t_hour, t_minute, t_second, t_meal_time
    FROM time_dim
  ),
  t_alt AS (
    SELECT t_time_sk, t_minute
    FROM time_dim
    WHERE t_hour BETWEEN 8 AND 10
  ),
  wr AS (
    SELECT *
    FROM web_returns
    WHERE wr_order_number NOT IN (
      SELECT wr_order_number
      FROM web_returns
      WHERE wr_return_amt > 1000
    )
  )
SELECT
  final.refunded_potential,
  final.returning_potential,
  final.refunded_income_low,
  final.returning_income_high,
  final.reason_desc,
  final.alt_reason_desc,
  final.return_hour,
  final.alt_minute,
  final.cat_val,
  final.total_return_amt,
  final.return_cnt,
  final.avg_return_amt_global,
  final.rn
FROM (
  SELECT
    agg.*, 
    ROW_NUMBER() OVER (PARTITION BY agg.refunded_potential ORDER BY agg.total_return_amt DESC) AS rn,
    (SELECT AVG(wr_return_amt) FROM web_returns) AS avg_return_amt_global
  FROM (
    SELECT
      hd_ref.hd_buy_potential                AS refunded_potential,
      hd_ret.ret_buy_potential                AS returning_potential,
      ib_ref.ib_lower_bound                   AS refunded_income_low,
      ib_ret.ib_upper_bound                   AS returning_income_high,
      r.r_reason_desc                         AS reason_desc,
      r_alt.r_reason_desc                     AS alt_reason_desc,
      t_ret.t_hour                            AS return_hour,
      t_alt.t_minute                          AS alt_minute,
      cat.value                               AS cat_val,
      SUM(wr.wr_return_amt)                  AS total_return_amt,
      COUNT(*)                                AS return_cnt
    FROM wr
      JOIN hd_ref   ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
      JOIN ib_ref   ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
      JOIN hd_ret   ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
      JOIN ib_ret   ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
      JOIN r        ON wr.wr_reason_sk = r.r_reason_sk
      JOIN r_alt    ON wr.wr_reason_sk = r_alt.r_reason_sk
      JOIN t_ret    ON wr.wr_returned_time_sk = t_ret.t_time_sk
      JOIN t_alt    ON wr.wr_returned_time_sk = t_alt.t_time_sk
      CROSS JOIN (SELECT value FROM (VALUES 'X', 'Y') AS v(value)) AS cat
    GROUP BY CUBE (
      hd_ref.hd_buy_potential,
      hd_ret.ret_buy_potential,
      ib_ref.ib_lower_bound,
      ib_ret.ib_upper_bound,
      r.r_reason_desc,
      r_alt.r_reason_desc,
      t_ret.t_hour,
      t_alt.t_minute,
      cat.value
    )
  ) agg
) final
WHERE final.rn <= 3
ORDER BY final.total_return_amt DESC, final.refunded_potential
OFFSET 5 ROWS FETCH NEXT 100 ROWS ONLY

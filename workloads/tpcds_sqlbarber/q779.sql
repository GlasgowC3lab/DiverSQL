SELECT
    ib.ib_income_band_sk,
    hd.hd_buy_potential,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    (SELECT wr2.wr_return_quantity
     FROM web_returns wr2
     WHERE wr2.wr_returned_date_sk = 2451373
     LIMIT 1) AS sample_wr_quantity
FROM catalog_returns cr
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN web_returns wr
  ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE cr.cr_returned_date_sk = 2450966
  AND ib.ib_lower_bound >= 10001
GROUP BY ib.ib_income_band_sk, hd.hd_buy_potential
HAVING SUM(cr.cr_return_amount) > 88.24

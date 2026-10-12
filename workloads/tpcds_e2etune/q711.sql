WITH refunded_demo AS (
  SELECT
    wr.wr_refunded_customer_sk,
    wr.wr_returned_date_sk,
    wr.wr_return_amt_inc_tax,
    wr.wr_net_loss,
    wr.wr_return_quantity,
    c.c_preferred_cust_flag,
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    hd.hd_income_band_sk
  FROM web_returns wr
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE c.c_preferred_cust_flag = 'Y'
    AND wr.wr_returned_date_sk BETWEEN 2451545 AND 2451910
)
SELECT
  hd_income_band_sk,
  hd_buy_potential,
  SUM(wr_return_amt_inc_tax) AS total_return_amount,
  SUM(wr_net_loss) AS total_net_loss,
  AVG(wr_return_quantity) AS avg_return_qty,
  COUNT(*) AS return_count
FROM refunded_demo
GROUP BY hd_income_band_sk, hd_buy_potential
HAVING SUM(wr_return_amt_inc_tax) > 10000
ORDER BY total_net_loss DESC
LIMIT 100

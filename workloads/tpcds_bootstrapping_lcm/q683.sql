SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq AS month_seq,
    hd_cust.hd_buy_potential,
    hd_cust.hd_income_band_sk,
    COUNT(DISTINCT c_ref.c_customer_sk) AS distinct_refunded_customers,
    COUNT(DISTINCT c_ret.c_customer_sk) AS distinct_returning_customers,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN hd_ref.hd_buy_potential = 'HIGH' THEN wr.wr_return_amt ELSE 0 END) AS high_potential_return_amount,
    MIN(d_ret.d_date) AS first_return_date,
    MAX(d_ret.d_date) AS last_return_date
FROM web_returns wr
JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN customer c_ref ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer c_ret ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN household_demographics hd_cust ON c_ref.c_current_hdemo_sk = hd_cust.hd_demo_sk
JOIN date_dim d_ship ON c_ref.c_first_shipto_date_sk = d_ship.d_date_sk
WHERE d_ret.d_year = 2022
  AND s.s_state = 'CA'
  AND hd_cust.hd_income_band_sk = 5
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    hd_cust.hd_buy_potential,
    hd_cust.hd_income_band_sk
HAVING SUM(wr.wr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100

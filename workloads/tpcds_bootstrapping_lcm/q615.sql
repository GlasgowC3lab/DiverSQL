SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    hd_ret.hd_buy_potential,
    hd_ref.hd_income_band_sk,
    ca_ret.ca_state AS returning_state,
    ca_ref.ca_state AS refunded_state,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS return_count,
    CASE
        WHEN SUM(wr.wr_return_amt) = 0 THEN 0
        ELSE SUM(wr.wr_net_loss) / SUM(wr.wr_return_amt)
    END AS loss_to_return_ratio
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN customer_address ca_ret
    ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
JOIN customer_address ca_ref
    ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year = 2022
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    hd_ret.hd_buy_potential,
    hd_ref.hd_income_band_sk,
    ca_ret.ca_state,
    ca_ref.ca_state
ORDER BY total_return_amount DESC
LIMIT 100

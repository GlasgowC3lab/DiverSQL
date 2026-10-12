SELECT
    s.s_store_name,
    s.s_state,
    dd.d_year,
    cd_ret.cd_gender,
    ca_ret.ca_location_type,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    SUM(wr.wr_return_tax) AS total_tax,
    SUM(wr.wr_return_amt_inc_tax) - SUM(wr.wr_return_tax) AS net_return_amt_excl_tax
FROM web_returns wr
JOIN date_dim dd
    ON wr.wr_returned_date_sk = dd.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dd.d_date_sk
JOIN customer_address ca_ret
    ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
JOIN customer_address ca_ref
    ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_demographics cd_ret
    ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_demographics cd_ref
    ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
WHERE dd.d_year BETWEEN 2020 AND 2022
  AND cd_ret.cd_credit_rating = 'Excellent'
  AND s.s_market_desc IS NOT NULL
GROUP BY
    s.s_store_name,
    s.s_state,
    dd.d_year,
    cd_ret.cd_gender,
    ca_ret.ca_location_type
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_net_loss DESC
LIMIT 100

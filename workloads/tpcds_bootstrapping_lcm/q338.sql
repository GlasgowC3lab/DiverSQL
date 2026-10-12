SELECT
    cc.cc_division_name,
    s.s_market_desc,
    d.d_year,
    d.d_current_month,
    ca_ret.ca_state AS returning_state,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS total_returns,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    SUM(wr.wr_return_quantity * wr.wr_return_amt) AS total_return_value,
    CASE
        WHEN SUM(wr.wr_net_loss) > 10000 THEN 'HIGH'
        WHEN SUM(wr.wr_net_loss) > 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_category
FROM web_returns AS wr
JOIN date_dim AS d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer_address AS ca_ret
    ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
JOIN customer_address AS ca_ref
    ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN store AS s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN call_center AS cc
    ON cc.cc_closed_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2015 AND 2022
    AND cc.cc_tax_percentage > 5.00
    AND s.s_market_desc IS NOT NULL
    AND ca_ret.ca_state IS NOT NULL
GROUP BY
    cc.cc_division_name,
    s.s_market_desc,
    d.d_year,
    d.d_current_month,
    ca_ret.ca_state
HAVING
    SUM(wr.wr_net_loss) > 500
ORDER BY
    total_net_loss DESC
LIMIT 100

SELECT
    s.s_store_id,
    ws.web_site_id,
    d.d_year,
    d.d_quarter_name,
    ca_ret.ca_state,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_quantity,
    SUM(CASE WHEN wr.wr_return_amt > 500 THEN wr.wr_return_amt ELSE 0 END) AS high_value_returns,
    SUM(CASE WHEN ca_ret.ca_gmt_offset > 0 THEN wr.wr_return_amt * (1 + ca_ret.ca_gmt_offset/24) ELSE wr.wr_return_amt END) AS adjusted_return_amt,
    MIN(d.d_date) AS first_return_date,
    MAX(d.d_date) AS last_return_date
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_ret
    ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
JOIN customer_address ca_ref
    ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
       OR ws.web_close_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND ca_ret.ca_country = 'United States'
GROUP BY
    s.s_store_id,
    ws.web_site_id,
    d.d_year,
    d.d_quarter_name,
    ca_ret.ca_state
HAVING SUM(wr.wr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100

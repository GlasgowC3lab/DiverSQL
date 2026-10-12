SELECT
    refunded_addr.ca_city AS refunded_city,
    returning_addr.ca_city AS returning_city,
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    s.s_store_name,
    s.s_county,
    COUNT(DISTINCT wr.wr_order_number) AS num_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN customer_address refunded_addr
    ON wr.wr_refunded_addr_sk = refunded_addr.ca_address_sk
JOIN customer_address returning_addr
    ON wr.wr_returning_addr_sk = returning_addr.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND s.s_state = 'CA'
GROUP BY refunded_addr.ca_city,
         returning_addr.ca_city,
         d.d_year,
         d.d_month_seq,
         r.r_reason_desc,
         s.s_store_name,
         s.s_county
ORDER BY total_return_amount DESC
LIMIT 100

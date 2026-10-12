SELECT
    s.s_store_name,
    dd.d_year,
    i.i_category,
    ca_refunded.ca_location_type,
    ca_returning.ca_state AS returning_state,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(wr.wr_return_quantity) AS total_quantity,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    CASE
        WHEN SUM(wr.wr_return_quantity) > 10 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    SUM(wr.wr_return_amt) / NULLIF(SUM(i.i_wholesale_cost * wr.wr_return_quantity), 0) AS return_to_wholesale_ratio
FROM web_returns wr
JOIN date_dim dd
    ON wr.wr_returned_date_sk = dd.d_date_sk
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN customer_address ca_refunded
    ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = dd.d_date_sk
WHERE dd.d_year BETWEEN 2015 AND 2022
GROUP BY ROLLUP(
    s.s_store_name,
    dd.d_year,
    i.i_category,
    ca_refunded.ca_location_type,
    ca_returning.ca_state
)
HAVING COUNT(*) > 5
ORDER BY total_net_loss DESC
LIMIT 100

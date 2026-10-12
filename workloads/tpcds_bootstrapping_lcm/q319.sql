SELECT
    d_return.d_year AS return_year,
    d_return.d_month_seq AS return_month,
    CASE
        WHEN t.t_hour < 12 THEN 'Morning'
        WHEN t.t_hour < 18 THEN 'Afternoon'
        ELSE 'Evening'
    END AS period_of_day,
    s.s_store_id,
    s.s_state,
    c_ret.c_customer_id AS returning_customer_id,
    c_ref.c_customer_id AS refunded_customer_id,
    COUNT(wr.wr_order_number) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN wr.wr_return_amt > 100 THEN wr.wr_return_amt ELSE 0 END) AS large_return_amount,
    DATE_DIFF('day', d_closed.d_date, d_return.d_date) AS days_between_store_close_and_return,
    DATE_DIFF('day', d_ship.d_date, d_return.d_date) AS days_between_customer_first_ship_and_return,
    DATE_DIFF('day', d_sales.d_date, d_return.d_date) AS days_between_customer_first_sales_and_return
FROM web_returns AS wr
INNER JOIN date_dim AS d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
INNER JOIN time_dim AS t
    ON wr.wr_returned_time_sk = t.t_time_sk
INNER JOIN customer AS c_ret
    ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
INNER JOIN customer AS c_ref
    ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
INNER JOIN store AS s
    ON TRUE
INNER JOIN date_dim AS d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
INNER JOIN date_dim AS d_ship
    ON c_ret.c_first_shipto_date_sk = d_ship.d_date_sk
INNER JOIN date_dim AS d_sales
    ON c_ret.c_first_sales_date_sk = d_sales.d_date_sk
GROUP BY
    d_return.d_year,
    d_return.d_month_seq,
    d_return.d_date,
    CASE
        WHEN t.t_hour < 12 THEN 'Morning'
        WHEN t.t_hour < 18 THEN 'Afternoon'
        ELSE 'Evening'
    END,
    s.s_store_id,
    s.s_state,
    c_ret.c_customer_id,
    c_ref.c_customer_id,
    d_closed.d_date,
    d_ship.d_date,
    d_sales.d_date

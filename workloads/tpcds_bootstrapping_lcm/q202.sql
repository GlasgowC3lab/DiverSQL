WITH return_summary AS (
    SELECT
        wr.wr_refunded_customer_sk,
        wr.wr_returning_customer_sk,
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM web_returns wr
    GROUP BY
        wr.wr_refunded_customer_sk,
        wr.wr_returning_customer_sk,
        wr.wr_returned_date_sk
)
SELECT
    c.c_customer_id           AS refunded_customer_id,
    c.c_email_address         AS refunded_email,
    rc.c_customer_id          AS returning_customer_id,
    rc.c_email_address        AS returning_email,
    d_ret.d_year              AS return_year,
    d_ret.d_month_seq         AS return_month,
    d_ret.d_day_name          AS return_day,
    rs.total_return_amt,
    rs.total_net_loss,
    rs.return_count,
    i.inv_item_sk,
    i.inv_quantity_on_hand,
    i.inv_warehouse_sk,
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_ship.d_year             AS ship_year,
    d_sales.d_year            AS sales_year,
    d_review.d_year           AS review_year
FROM return_summary rs
JOIN customer c
    ON rs.wr_refunded_customer_sk = c.c_customer_sk
JOIN customer rc
    ON rs.wr_returning_customer_sk = rc.c_customer_sk
JOIN date_dim d_ret
    ON rs.wr_returned_date_sk = d_ret.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_review
    ON c.c_last_review_date = d_review.d_date_sk
WHERE d_ret.d_year = 2021
ORDER BY rs.total_return_amt DESC
LIMIT 200

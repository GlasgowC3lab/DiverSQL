WITH agg AS (
    SELECT
        cr.c_customer_id AS refunded_customer_id,
        cr.c_email_address AS refunded_email,
        cr2.c_customer_id AS returning_customer_id,
        cr2.c_email_address AS returning_email,
        d_ret.d_date AS return_date,
        r.r_reason_desc AS return_reason,
        s.s_store_name AS store_name,
        s.s_city AS store_city,
        d_first_ship.d_date AS first_ship_date,
        d_first_sales.d_date AS first_sales_date,
        COUNT(*) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_fee) AS total_fees,
        AVG(wr.wr_net_loss) AS avg_net_loss,
        CASE
            WHEN SUM(wr.wr_return_amt) > 1000 THEN 'HIGH'
            WHEN SUM(wr.wr_return_amt) BETWEEN 500 AND 1000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS return_amount_category
    FROM web_returns wr
    JOIN customer cr
        ON wr.wr_refunded_customer_sk = cr.c_customer_sk
    JOIN customer cr2
        ON wr.wr_returning_customer_sk = cr2.c_customer_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    LEFT JOIN date_dim d_first_ship
        ON cr.c_first_shipto_date_sk = d_first_ship.d_date_sk
    LEFT JOIN date_dim d_first_sales
        ON cr.c_first_sales_date_sk = d_first_sales.d_date_sk
    GROUP BY
        cr.c_customer_id,
        cr.c_email_address,
        cr2.c_customer_id,
        cr2.c_email_address,
        d_ret.d_date,
        r.r_reason_desc,
        s.s_store_name,
        s.s_city,
        d_first_ship.d_date,
        d_first_sales.d_date
)
SELECT
    refunded_customer_id,
    refunded_email,
    returning_customer_id,
    returning_email,
    return_date,
    return_reason,
    store_name,
    store_city,
    first_ship_date,
    first_sales_date,
    num_returns,
    total_return_amount,
    total_fees,
    avg_net_loss,
    return_amount_category,
    ROW_NUMBER() OVER (PARTITION BY refunded_customer_id ORDER BY total_return_amount DESC) AS customer_return_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100

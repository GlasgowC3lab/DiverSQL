WITH aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        r.r_reason_desc,
        d.d_year,
        d.d_month_seq,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amount,
        COUNT(DISTINCT c_returning.c_customer_sk) AS distinct_returning_customers,
        MIN(d.d_date) AS first_return_date,
        MAX(d.d_date) AS last_return_date,
        MIN(d.d_date) AS store_closed_date,
        MIN(d_ref_shipto.d_date) AS refunded_customer_earliest_ship_date,
        MIN(d_ref_sales.d_date)   AS refunded_customer_earliest_sales_date
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c_refunded
        ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer c_returning
        ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
    LEFT JOIN date_dim d_ref_shipto
        ON c_refunded.c_first_shipto_date_sk = d_ref_shipto.d_date_sk
    LEFT JOIN date_dim d_ref_sales
        ON c_refunded.c_first_sales_date_sk = d_ref_sales.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        r.r_reason_desc,
        d.d_year,
        d.d_month_seq
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.s_city,
    a.s_state,
    a.r_reason_desc,
    a.d_year,
    a.d_month_seq,
    a.total_returns,
    a.total_return_amount,
    a.total_net_loss,
    a.avg_return_amount,
    a.distinct_returning_customers,
    a.first_return_date,
    a.last_return_date,
    a.store_closed_date,
    a.refunded_customer_earliest_ship_date,
    a.refunded_customer_earliest_sales_date,
    RANK() OVER (PARTITION BY a.d_year, a.d_month_seq ORDER BY a.total_net_loss DESC) AS net_loss_rank
FROM aggregated a
ORDER BY a.d_year DESC, a.d_month_seq DESC, net_loss_rank

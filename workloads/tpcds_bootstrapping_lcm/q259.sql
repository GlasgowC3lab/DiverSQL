WITH store_monthly_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month,
        d_ret.d_holiday AS holiday_flag,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        AVG(wr.wr_return_amt) AS avg_return_amount,
        SUM(wr.wr_return_tax) AS total_return_tax,
        COUNT(*) AS total_return_events,
        COUNT(DISTINCT c_refunded.c_customer_sk) AS distinct_refunded_customers,
        COUNT(DISTINCT c_returning.c_customer_sk) AS distinct_returning_customers,
        SUM(CASE WHEN c_refunded.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_refunded_customer_returns,
        d_shipto.d_year AS first_shipto_year,
        d_shipto.d_month_seq AS first_shipto_month
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN customer c_refunded
        ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer c_returning
        ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
    JOIN date_dim d_shipto
        ON c_refunded.c_first_shipto_date_sk = d_shipto.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year BETWEEN 1998 AND 2002
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_ret.d_year,
        d_ret.d_month_seq,
        d_ret.d_holiday,
        d_shipto.d_year,
        d_shipto.d_month_seq
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    return_year,
    return_month,
    holiday_flag,
    total_net_loss,
    total_return_quantity,
    avg_return_amount,
    total_return_tax,
    total_return_events,
    distinct_refunded_customers,
    distinct_returning_customers,
    preferred_refunded_customer_returns,
    first_shipto_year,
    first_shipto_month,
    RANK() OVER (PARTITION BY s_store_id ORDER BY total_net_loss DESC) AS net_loss_rank
FROM store_monthly_returns
ORDER BY total_net_loss DESC
LIMIT 100

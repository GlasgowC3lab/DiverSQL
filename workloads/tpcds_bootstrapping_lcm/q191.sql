WITH aggregated AS (
    SELECT
        cc.cc_name AS call_center_name,
        s.s_store_name AS store_name,
        d_return.d_year AS return_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        AVG(c_refunded.c_birth_year) AS avg_refunded_birth_year,
        AVG(c_returning.c_birth_year) AS avg_returning_birth_year,
        MIN(d_cc_closed.d_date) AS call_center_closed_date,
        MIN(d_cc_open.d_date) AS call_center_open_date,
        MIN(d_customer_shipto.d_date) AS customer_first_shipto_date,
        MIN(d_customer_sales.d_date) AS customer_first_sales_date
    FROM catalog_returns cr
    INNER JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    INNER JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    INNER JOIN customer c_refunded
        ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    INNER JOIN customer c_returning
        ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    INNER JOIN store s
        ON s.s_closed_date_sk = d_return.d_date_sk
    INNER JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    INNER JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    INNER JOIN date_dim d_customer_shipto
        ON c_refunded.c_first_shipto_date_sk = d_customer_shipto.d_date_sk
    INNER JOIN date_dim d_customer_sales
        ON c_refunded.c_first_sales_date_sk = d_customer_sales.d_date_sk
    GROUP BY
        cc.cc_name,
        s.s_store_name,
        d_return.d_year
)
SELECT
    call_center_name,
    store_name,
    return_year,
    total_return_amount,
    total_net_loss,
    return_count,
    avg_refunded_birth_year,
    avg_returning_birth_year,
    call_center_closed_date,
    call_center_open_date,
    customer_first_shipto_date,
    customer_first_sales_date,
    ROW_NUMBER() OVER (PARTITION BY call_center_name ORDER BY total_net_loss DESC) AS rank_by_net_loss
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100

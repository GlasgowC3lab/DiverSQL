WITH agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        cc.cc_division_name,
        s.s_store_name,
        s.s_city,
        s.s_state,
        c_refunded.c_customer_id AS refunded_customer_id,
        c_refunded.c_first_name AS refunded_first_name,
        c_refunded.c_last_name AS refunded_last_name,
        c_returning.c_customer_id AS returning_customer_id,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        AVG(wr.wr_return_quantity) AS avg_return_quantity,
        MAX(wr.wr_return_tax) AS max_return_tax,
        MIN(wr.wr_return_tax) AS min_return_tax,
        SUM(wr.wr_return_amt_inc_tax) - SUM(wr.wr_return_tax) AS total_return_excluding_tax
    FROM
        web_returns wr
    JOIN
        date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN
        customer c_refunded ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN
        customer c_returning ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
    JOIN
        call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN
        store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2000 AND 2005
        AND cc.cc_state = 'CA'
        AND s.s_state = 'CA'
    GROUP BY
        cc.cc_name,
        cc.cc_division_name,
        s.s_store_name,
        s.s_city,
        s.s_state,
        c_refunded.c_customer_id,
        c_refunded.c_first_name,
        c_refunded.c_last_name,
        c_returning.c_customer_id,
        d.d_year,
        d.d_month_seq,
        d.d_day_name
)
SELECT
    *,
    DENSE_RANK() OVER (PARTITION BY call_center_name ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100

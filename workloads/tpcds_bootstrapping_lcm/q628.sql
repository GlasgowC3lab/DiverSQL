WITH store_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d_closure.d_year,
        d_closure.d_current_month,
        d_sales.d_quarter_name,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS total_returns,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
        MIN(c.c_birth_country) AS example_birth_country
    FROM store s
    JOIN date_dim d_closure
        ON s.s_closed_date_sk = d_closure.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_closure.d_date_sk
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN date_dim d_sales
        ON c.c_first_sales_date_sk = d_sales.d_date_sk
    WHERE s.s_closed_date_sk IS NOT NULL
      AND wr.wr_net_loss > 0
    GROUP BY s.s_store_id, s.s_store_name, s.s_state,
             d_closure.d_year, d_closure.d_current_month,
             d_sales.d_quarter_name
)
SELECT
    sr.s_store_id,
    sr.s_store_name,
    sr.s_state,
    sr.d_year,
    sr.d_current_month,
    sr.d_quarter_name,
    sr.total_net_loss,
    sr.total_returns,
    sr.avg_return_amt,
    sr.distinct_customers,
    sr.example_birth_country,
    RANK() OVER (PARTITION BY sr.d_year ORDER BY sr.total_net_loss DESC) AS loss_rank
FROM store_returns sr
ORDER BY sr.total_net_loss DESC
LIMIT 100

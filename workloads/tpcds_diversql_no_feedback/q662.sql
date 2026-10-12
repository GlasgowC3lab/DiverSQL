WITH joined_data AS (
    SELECT
        d_sold.d_year,
        st.s_store_id,
        st.s_store_name,
        p.p_promo_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.ss_net_paid,
        wr.wr_net_loss
    FROM store_sales ss
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    LEFT JOIN income_band ib ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN date_dim d_closed ON st.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    LEFT JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN household_demographics hd_refund ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    LEFT JOIN household_demographics hd_returning ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
)
SELECT
    d_year,
    s_store_id,
    s_store_name,
    p_promo_name,
    ib_lower_bound,
    ib_upper_bound,
    SUM(ss_net_paid) AS total_sales,
    SUM(wr_net_loss) AS total_return_loss,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
FROM joined_data
WHERE d_year BETWEEN 1999 AND 2001
GROUP BY d_year, s_store_id, s_store_name, p_promo_name, ib_lower_bound, ib_upper_bound
HAVING SUM(ss_net_paid) > 10000
ORDER BY total_sales DESC
LIMIT 100

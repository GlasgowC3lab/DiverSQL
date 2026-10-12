WITH aggregated_returns AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month_seq,
        wp.wp_url AS page_url,
        wp.wp_type AS page_type,
        hd_ret.hd_income_band_sk AS returning_income_band,
        hd_ref.hd_income_band_sk AS refunded_income_band,
        COUNT(DISTINCT wr.wr_order_number) AS total_orders,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_refunded_cash) AS total_refunded_cash,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
        MIN(d_store.d_date) AS store_closed_date,
        MIN(d_creation.d_date) AS page_creation_date,
        MIN(d_access.d_date) AS page_access_date
    FROM web_returns wr
    JOIN date_dim d_ret
      ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN household_demographics hd_ret
      ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN household_demographics hd_ref
      ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_creation
      ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
      ON wp.wp_access_date_sk = d_access.d_date_sk
    JOIN store s
      ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_store
      ON s.s_closed_date_sk = d_store.d_date_sk
    WHERE d_ret.d_year = 2022
      AND s.s_state = 'CA'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_ret.d_year,
        d_ret.d_month_seq,
        wp.wp_url,
        wp.wp_type,
        hd_ret.hd_income_band_sk,
        hd_ref.hd_income_band_sk
)
SELECT
    store_id,
    store_name,
    store_city,
    store_state,
    return_year,
    return_month_seq,
    page_url,
    page_type,
    returning_income_band,
    refunded_income_band,
    total_orders,
    total_return_amount,
    total_refunded_cash,
    total_return_quantity,
    avg_return_amt_inc_tax,
    store_closed_date,
    page_creation_date,
    page_access_date,
    ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY total_return_amount DESC) AS store_rank
FROM aggregated_returns
ORDER BY total_return_amount DESC
LIMIT 100

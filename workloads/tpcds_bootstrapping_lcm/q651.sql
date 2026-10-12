WITH wr_data AS (
    SELECT
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month,
        d_ret.d_day_name AS return_day,
        t.t_hour,
        t.t_meal_time,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_closed_date_sk
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
)

SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    cp.cp_description,
    d_start.d_year AS catalog_start_year,
    d_start.d_month_seq AS catalog_start_month,
    d_end.d_year AS catalog_end_year,
    d_end.d_month_seq AS catalog_end_month,
    wd.s_store_name,
    wd.s_city,
    wd.s_state,
    wd.t_hour,
    wd.t_meal_time,
    COUNT(*) AS total_returns,
    SUM(wd.wr_return_amt) AS total_return_amount,
    SUM(wd.wr_return_tax) AS total_return_tax,
    SUM(wd.wr_net_loss) AS total_net_loss,
    AVG(wd.wr_return_quantity) AS avg_return_quantity,
    ROUND(SUM(wd.wr_return_amt) / NULLIF(COUNT(*), 0), 2) AS avg_return_amount_per_return
FROM catalog_page cp
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN wr_data wd ON wd.wr_returned_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_type,
    cp.cp_description,
    d_start.d_year,
    d_start.d_month_seq,
    d_end.d_year,
    d_end.d_month_seq,
    wd.s_store_name,
    wd.s_city,
    wd.s_state,
    wd.t_hour,
    wd.t_meal_time
ORDER BY total_return_amount DESC
LIMIT 100

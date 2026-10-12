WITH agg AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        cp.cp_catalog_page_number,
        d_start.d_date AS catalog_page_start_date,
        d_end.d_date AS catalog_page_end_date,
        s.s_state,
        s.s_city,
        t.t_meal_time,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM catalog_page cp
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_end.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_end.d_date_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    GROUP BY
        cp.cp_department,
        cp.cp_type,
        cp.cp_catalog_page_number,
        d_start.d_date,
        d_end.d_date,
        s.s_state,
        s.s_city,
        t.t_meal_time
)
SELECT
    cp_department,
    cp_type,
    cp_catalog_page_number,
    catalog_page_start_date,
    catalog_page_end_date,
    s_state,
    s_city,
    t_meal_time,
    total_return_amount,
    total_net_loss,
    return_count,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100

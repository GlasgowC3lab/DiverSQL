WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        dd_ret.d_date AS return_date,
        td.t_hour,
        td.t_meal_time,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT wp.wp_web_page_id) AS unique_page_cnt,
        SUM(wp.wp_image_count) AS total_image_cnt,
        SUM(wp.wp_link_count) AS total_link_cnt
    FROM store_returns sr
    JOIN date_dim dd_ret ON sr.sr_returned_date_sk = dd_ret.d_date_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim dd_store_closed ON s.s_closed_date_sk = dd_store_closed.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = dd_ret.d_date_sk
    WHERE dd_ret.d_year = 2022
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        dd_ret.d_date,
        td.t_hour,
        td.t_meal_time
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    return_date,
    t_hour,
    t_meal_time,
    total_return_amt,
    total_return_qty,
    total_net_loss,
    unique_page_cnt,
    total_image_cnt,
    total_link_cnt,
    ROW_NUMBER() OVER (ORDER BY total_return_amt DESC) AS rank
FROM agg
ORDER BY total_return_amt DESC
LIMIT 100

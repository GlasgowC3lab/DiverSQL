WITH weekly_store_metrics AS (
    SELECT
        dr.d_year,
        dr.d_week_seq,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        ds.d_date AS store_closed_date,
        s.s_floor_space AS floor_space,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
        SUM(sr.sr_return_quantity) AS total_qty,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_store_credit) AS total_store_credit,
        AVG(sr.sr_fee) AS avg_fee,
        SUM(sr.sr_return_amt) FILTER (WHERE t.t_am_pm = 'AM') AS am_return_amount,
        SUM(sr.sr_return_amt) FILTER (WHERE t.t_am_pm = 'PM') AS pm_return_amount,
        COUNT(DISTINCT wp.wp_web_page_id) AS unique_web_pages,
        SUM(wp.wp_image_count) AS total_images,
        AVG(wp.wp_char_count) AS avg_char_count
    FROM store_returns sr
    JOIN date_dim dr
        ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim ds
        ON s.s_closed_date_sk = ds.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = dr.d_date_sk
       AND wp.wp_access_date_sk = dr.d_date_sk
    WHERE dr.d_year BETWEEN 2000 AND 2003
      AND s.s_state IN ('CA', 'NY')
      AND t.t_shift = 'Evening'
    GROUP BY
        dr.d_year,
        dr.d_week_seq,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        ds.d_date,
        s.s_floor_space
    HAVING COUNT(*) > 10
)
SELECT
    w.*,
    CASE WHEN w.floor_space > 20000 THEN 'Large' ELSE 'Small' END AS store_size_category,
    ROW_NUMBER() OVER (PARTITION BY w.d_year, w.d_week_seq ORDER BY w.total_return_amount DESC) AS week_store_rank
FROM weekly_store_metrics w
ORDER BY w.d_year, w.d_week_seq, w.total_return_amount DESC
LIMIT 100

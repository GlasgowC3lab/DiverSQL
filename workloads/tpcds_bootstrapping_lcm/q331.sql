WITH agg AS (
    SELECT
        d_ret.d_date AS return_date,
        d_ret.d_year AS d_year,
        d_ret.d_current_quarter AS d_current_quarter,
        s.s_store_id AS s_store_id,
        s.s_store_name AS s_store_name,
        t.t_hour AS t_hour,
        d_ret.d_holiday AS d_holiday,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
        SUM(wr.wr_return_tax) AS total_return_tax,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_fee) AS avg_fee,
        SUM(wr.wr_return_quantity) AS total_quantity,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
        AVG(wp.wp_image_count) AS avg_image_count,
        MIN(wp.wp_max_ad_count) AS min_max_ad_count
    FROM web_returns wr
    JOIN date_dim d_ret
      ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t
      ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN store s
      ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_creation
      ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
      ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE d_ret.d_year = 2022
      AND t.t_hour BETWEEN 9 AND 21
      AND s.s_state = 'CA'
    GROUP BY
        d_ret.d_date,
        d_ret.d_year,
        d_ret.d_current_quarter,
        s.s_store_id,
        s.s_store_name,
        t.t_hour,
        d_ret.d_holiday
    HAVING COUNT(*) > 5
)
SELECT
    return_date,
    d_year,
    d_current_quarter,
    s_store_id,
    s_store_name,
    t_hour,
    total_returns,
    total_return_amount,
    total_return_amount_inc_tax,
    total_return_tax,
    total_net_loss,
    avg_fee,
    total_quantity,
    distinct_pages,
    avg_image_count,
    min_max_ad_count,
    CASE WHEN d_holiday = 'Y' THEN 'Holiday' ELSE 'Regular' END AS day_type,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_net_loss DESC) AS store_loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100

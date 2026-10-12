SELECT
    a.s_store_id,
    a.s_store_name,
    a.s_city,
    a.cp_type,
    a.cp_description,
    a.return_year,
    a.return_month,
    a.total_net_loss,
    a.distinct_returns,
    a.avg_return_quantity,
    a.total_store_credit,
    a.total_fee,
    a.distinct_web_pages,
    a.total_image_count,
    a.total_link_count,
    ROW_NUMBER() OVER (ORDER BY a.total_net_loss DESC) AS loss_rank
FROM (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        cp.cp_type,
        cp.cp_description,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns,
        AVG(sr.sr_return_quantity) AS avg_return_quantity,
        SUM(sr.sr_store_credit) AS total_store_credit,
        SUM(sr.sr_fee) AS total_fee,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
        SUM(wp.wp_image_count) AS total_image_count,
        SUM(wp.wp_link_count) AS total_link_count
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN catalog_page cp
        ON 1 = 1
    JOIN date_dim cp_start
        ON cp.cp_start_date_sk = cp_start.d_date_sk
    JOIN date_dim cp_end
        ON cp.cp_end_date_sk = cp_end.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_ret.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    WHERE d_ret.d_date BETWEEN cp_start.d_date AND cp_end.d_date
      AND (d_store_closed.d_date IS NULL OR d_store_closed.d_date > d_ret.d_date)
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        cp.cp_type,
        cp.cp_description,
        d_ret.d_year,
        d_ret.d_month_seq
) a
ORDER BY a.total_net_loss DESC

WITH aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_ret.d_year,
        d_ret.d_month_seq,
        t.t_hour,
        t.t_meal_time,
        wp.wp_type,
        COUNT(DISTINCT cr.cr_item_sk) AS distinct_items_returned,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        COUNT(*) AS total_returns
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_ret.d_date_sk
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE d_ret.d_year = 2022
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_ret.d_year,
        d_ret.d_month_seq,
        t.t_hour,
        t.t_meal_time,
        wp.wp_type
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.d_year,
    a.d_month_seq,
    a.t_hour,
    a.t_meal_time,
    a.wp_type,
    a.distinct_items_returned,
    a.total_return_amount,
    a.total_net_loss,
    a.avg_return_quantity,
    a.total_returns,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.total_net_loss DESC) AS net_loss_rank_by_store
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 100

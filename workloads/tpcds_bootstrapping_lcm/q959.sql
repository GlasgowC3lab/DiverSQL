WITH returns_by_store_month AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        dr.d_year,
        dr.d_month_seq,
        CASE WHEN s.s_floor_space > 200000 THEN 'Large' ELSE 'Small' END AS store_size_category,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages_created,
        MAX(wp.wp_image_count) AS max_image_count,
        SUM(sr.sr_return_quantity) / NULLIF(s.s_floor_space, 0) AS return_qty_per_floor_space,
        DATE_DIFF('day', dc.d_date, dr.d_date) AS days_between_return_and_store_close
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim dc ON s.s_closed_date_sk = dc.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = dr.d_date_sk
    WHERE sr.sr_net_loss > 0
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        dr.d_year,
        dr.d_month_seq,
        s.s_floor_space,
        dc.d_date,
        dr.d_date
    HAVING SUM(sr.sr_net_loss) > 1000
)
SELECT
    r.s_store_id,
    r.s_store_name,
    r.s_state,
    r.store_size_category,
    r.d_year,
    r.d_month_seq,
    r.total_net_loss,
    r.total_return_qty,
    r.avg_wholesale_cost,
    r.distinct_pages_created,
    r.max_image_count,
    r.return_qty_per_floor_space,
    r.days_between_return_and_store_close,
    SUM(r.total_net_loss) OVER (
        PARTITION BY r.s_store_id
        ORDER BY r.d_year, r.d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_loss
FROM returns_by_store_month r
ORDER BY r.total_net_loss DESC
LIMIT 100

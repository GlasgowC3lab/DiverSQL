WITH page_info AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_type,
        wp.wp_image_count,
        wp.wp_link_count,
        d_creation.d_year AS creation_year,
        d_access.d_year AS access_year
    FROM web_page wp
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
),
agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_ret.d_date,
        d_ret.d_year,
        d_ret.d_month_seq,
        p.wp_type,
        COUNT(DISTINCT wr.wr_order_number) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_tax) AS total_return_tax,
        AVG(wr.wr_return_quantity) AS avg_return_quantity,
        SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_on_hand,
        MAX(p.wp_image_count) AS max_image_count,
        MIN(p.wp_link_count) AS min_link_count,
        p.creation_year,
        p.access_year
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_ret.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN page_info p
        ON wp.wp_web_page_sk = p.wp_web_page_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_ret.d_date,
        d_ret.d_year,
        d_ret.d_month_seq,
        p.wp_type,
        p.creation_year,
        p.access_year
)
SELECT
    agg.s_store_id,
    agg.s_store_name,
    agg.d_date,
    agg.d_year,
    agg.d_month_seq,
    agg.wp_type,
    agg.num_returns,
    agg.total_return_amount,
    agg.total_return_tax,
    agg.avg_return_quantity,
    agg.total_inventory_on_hand,
    agg.max_image_count,
    agg.min_link_count,
    agg.creation_year,
    agg.access_year,
    RANK() OVER (PARTITION BY agg.d_year ORDER BY agg.total_return_amount DESC) AS rank_in_year
FROM agg
ORDER BY agg.total_return_amount DESC
LIMIT 100

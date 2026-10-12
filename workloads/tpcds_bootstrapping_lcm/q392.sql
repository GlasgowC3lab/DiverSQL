SELECT
    agg.w_warehouse_name,
    agg.d_year,
    agg.d_month_seq,
    agg.d_date,
    agg.total_quantity_on_hand,
    agg.closed_store_count,
    agg.pages_created_on_date,
    agg.pages_accessed_on_date,
    ROW_NUMBER() OVER (PARTITION BY agg.d_year ORDER BY agg.total_quantity_on_hand DESC) AS inventory_rank_yearly
FROM (
    SELECT
        w.w_warehouse_name,
        d_inv.d_year,
        d_inv.d_month_seq,
        d_inv.d_date,
        SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand,
        COUNT(DISTINCT s.s_store_id) AS closed_store_count,
        COUNT(DISTINCT wp_create.wp_web_page_id) AS pages_created_on_date,
        COUNT(DISTINCT wp_access.wp_web_page_id) AS pages_accessed_on_date
    FROM inventory i
    JOIN date_dim d_inv
        ON i.inv_date_sk = d_inv.d_date_sk
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d_inv.d_date_sk
    LEFT JOIN web_page wp_create
        ON wp_create.wp_creation_date_sk = d_inv.d_date_sk
    LEFT JOIN web_page wp_access
        ON wp_access.wp_access_date_sk = d_inv.d_date_sk
    GROUP BY
        w.w_warehouse_name,
        d_inv.d_year,
        d_inv.d_month_seq,
        d_inv.d_date
) agg
ORDER BY agg.d_year DESC, agg.total_quantity_on_hand DESC

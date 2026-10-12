WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        SUM(i.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT wp.wp_web_page_id) AS pages_created,
        COUNT(DISTINCT wp_access.wp_web_page_id) AS pages_accessed,
        COUNT(DISTINCT ws.web_site_id) AS sites_opened,
        COUNT(DISTINCT ws_close.web_site_id) AS sites_closed
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN web_site ws_close
        ON ws_close.web_close_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_page wp_access
        ON wp_access.wp_access_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, s.s_store_id, s.s_store_name, s.s_state
),
ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY d_year ORDER BY total_inventory DESC) AS inventory_rank
    FROM base
)
SELECT
    d_year,
    d_month_seq,
    s_store_id,
    s_store_name,
    s_state,
    total_inventory,
    pages_created,
    pages_accessed,
    sites_opened,
    sites_closed,
    inventory_rank
FROM ranked
WHERE inventory_rank <= 5
ORDER BY d_year, inventory_rank

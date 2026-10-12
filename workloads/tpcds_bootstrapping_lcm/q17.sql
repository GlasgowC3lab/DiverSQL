WITH daily_agg AS (
    SELECT
        d_closed.d_date AS closed_date,
        d_closed.d_year,
        d_closed.d_month_seq,
        d_closed.d_day_name,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT s.s_store_sk) AS stores_closed,
        COUNT(DISTINCT cc.cc_call_center_sk) AS call_centers_closed,
        COUNT(DISTINCT cp.cp_catalog_page_sk) AS catalog_pages_ended,
        AVG(s.s_tax_percentage) AS avg_store_tax_pct,
        AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
        MIN(d_open.d_date) AS earliest_open_date,
        MIN(d_cp_start.d_date) AS earliest_catalog_start_date
    FROM date_dim d_closed
    LEFT JOIN inventory i
        ON i.inv_date_sk = d_closed.d_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN call_center cc
        ON cc.cc_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_end_date_sk = d_closed.d_date_sk
    LEFT JOIN date_dim d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
    LEFT JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    WHERE d_closed.d_year BETWEEN 2000 AND 2020
    GROUP BY d_closed.d_date, d_closed.d_year, d_closed.d_month_seq, d_closed.d_day_name
)
SELECT
    closed_date,
    d_year,
    d_month_seq,
    d_day_name,
    total_inventory_qty,
    stores_closed,
    call_centers_closed,
    catalog_pages_ended,
    avg_store_tax_pct,
    avg_cc_tax_pct,
    earliest_open_date,
    earliest_catalog_start_date,
    ROW_NUMBER() OVER (ORDER BY total_inventory_qty DESC) AS inventory_rank
FROM daily_agg
ORDER BY inventory_rank
LIMIT 100

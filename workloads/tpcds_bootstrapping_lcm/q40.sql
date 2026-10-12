WITH daily_metrics AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        COALESCE(SUM(i.inv_quantity_on_hand), 0) AS total_inv_qty,
        COUNT(DISTINCT s.s_store_id) AS closed_store_cnt,
        COUNT(DISTINCT cc.cc_call_center_id) AS closed_cc_cnt,
        AVG(s.s_tax_percentage) AS avg_store_tax,
        AVG(cc.cc_tax_percentage) AS avg_cc_tax,
        COUNT(DISTINCT cp_start.cp_catalog_page_id) AS catalog_pages_started,
        COUNT(DISTINCT cp_end.cp_catalog_page_id) AS catalog_pages_ended,
        MAX(s.s_floor_space) AS max_store_floor_space,
        MIN(cc.cc_sq_ft) AS min_cc_sq_ft,
        AVG(DATE_DIFF('day', d_open.d_date, d.d_date)) AS avg_days_between_open_close
    FROM date_dim d
    LEFT JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp_start
        ON cp_start.cp_start_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp_end
        ON cp_end.cp_end_date_sk = d.d_date_sk
    LEFT JOIN date_dim d_open
        ON d_open.d_date_sk = cc.cc_open_date_sk
    WHERE d.d_date >= DATE '2023-01-01'
      AND d.d_date <= DATE '2023-12-31'
    GROUP BY d.d_date, d.d_year, d.d_month_seq
)
SELECT
    dm.d_date,
    dm.d_year,
    dm.d_month_seq,
    dm.total_inv_qty,
    dm.closed_store_cnt,
    dm.closed_cc_cnt,
    dm.avg_store_tax,
    dm.avg_cc_tax,
    dm.catalog_pages_started,
    dm.catalog_pages_ended,
    dm.max_store_floor_space,
    dm.min_cc_sq_ft,
    dm.avg_days_between_open_close,
    SUM(dm.total_inv_qty) OVER (ORDER BY dm.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_inv_qty,
    ROW_NUMBER() OVER (ORDER BY dm.total_inv_qty DESC) AS inv_qty_rank
FROM daily_metrics dm
ORDER BY dm.d_date

SELECT
    t.cc_call_center_id,
    t.cc_name,
    t.cc_employees,
    t.cc_tax_percentage,
    t.s_store_id,
    t.s_store_name,
    t.s_number_employees,
    t.s_floor_space,
    t.store_floor_space_sqm,
    t.cp_catalog_page_id,
    t.cp_catalog_number,
    t.cp_type,
    t.d_year,
    t.d_month_seq,
    t.d_day_name,
    t.cc_open_date,
    t.cc_closed_date,
    t.cc_open_to_closed_days,
    t.cp_start_date,
    t.cp_end_date,
    t.cp_duration_days,
    t.tax_category
FROM (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_employees,
        cc.cc_tax_percentage,
        s.s_store_id,
        s.s_store_name,
        s.s_number_employees,
        s.s_floor_space,
        s.s_floor_space * 0.092903 AS store_floor_space_sqm,
        cp.cp_catalog_page_id,
        cp.cp_catalog_number,
        cp.cp_type,
        d_cc_closed.d_year AS d_year,
        d_cc_closed.d_month_seq AS d_month_seq,
        d_cc_closed.d_day_name AS d_day_name,
        d_cc_open.d_date AS cc_open_date,
        d_cc_closed.d_date AS cc_closed_date,
        date_diff('day', d_cc_open.d_date, d_cc_closed.d_date) AS cc_open_to_closed_days,
        d_cp_start.d_date AS cp_start_date,
        d_cp_end.d_date AS cp_end_date,
        date_diff('day', d_cp_start.d_date, d_cp_end.d_date) AS cp_duration_days,
        CASE WHEN cc.cc_tax_percentage > 10 THEN 'High Tax' ELSE 'Low Tax' END AS tax_category,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY d_cc_closed.d_date DESC) AS rn_store_latest_closed
    FROM call_center cc
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_cc_closed.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_end_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    WHERE cc.cc_employees > 100
      AND s.s_number_employees > 50
      AND cp.cp_type = 'Holiday'
      AND d_cc_closed.d_year = 2023
) t
WHERE t.rn_store_latest_closed = 1
ORDER BY t.cc_employees DESC, t.s_floor_space DESC
LIMIT 100

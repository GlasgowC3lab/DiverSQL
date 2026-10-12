WITH
    key_set_diff AS (
        SELECT w_warehouse_id
        FROM warehouse
        WHERE w_state = 'CA'
        EXCEPT
        SELECT w_warehouse_id
        FROM warehouse
        WHERE w_state = 'CA' AND w_city = 'San Francisco'
    ),
    base_chain AS (
        SELECT
            d.d_year,
            w.w_warehouse_id,
            w.w_warehouse_name,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            cr.cr_return_amount,
            r.r_reason_desc,
            t.t_hour,
            t.t_am_pm,
            ca.ca_state,
            ib.ib_upper_bound,
            CASE WHEN sr.sr_return_quantity > 20 THEN 'Large' ELSE 'Small' END AS return_size_category
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        FULL OUTER JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE d.d_year = 2000
          AND t.t_hour = 13
          AND ca.ca_state = 'CA'
          AND w.w_warehouse_id IN (SELECT w_warehouse_id FROM key_set_diff)
          AND sm.sm_type = 'AIR'
          AND ib.ib_upper_bound >= 50000
          AND r.r_reason_desc LIKE '%damage%'
    ),
    second_chain AS (
        SELECT
            d.d_year,
            w.w_warehouse_id,
            w.w_warehouse_name,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            cr.cr_return_amount,
            r.r_reason_desc,
            t.t_hour,
            t.t_am_pm,
            ca.ca_state,
            ib.ib_upper_bound,
            CASE WHEN sr.sr_return_quantity > 20 THEN 'Large' ELSE 'Small' END AS return_size_category
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        FULL OUTER JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE d.d_year = 2001
          AND t.t_hour = 17
          AND ca.ca_state = 'NY'
          AND w.w_warehouse_id IN (SELECT w_warehouse_id FROM key_set_diff)
          AND sm.sm_type = 'RAIL'
          AND ib.ib_upper_bound >= 40000
          AND r.r_reason_desc LIKE '%defect%'
    )
SELECT
    d_year,
    w_warehouse_name,
    return_size_category,
    COUNT(*) AS transaction_count,
    SUM(sr_return_amt) AS total_store_return_amount,
    AVG(cr_return_amount) AS avg_catalog_return_amount,
    MIN(sr_return_quantity) AS min_return_qty,
    MAX(sr_return_quantity) AS max_return_qty
FROM (
    SELECT * FROM base_chain
    UNION
    SELECT * FROM second_chain
) AS u
GROUP BY d_year, w_warehouse_name, return_size_category
ORDER BY total_store_return_amount DESC
LIMIT 100

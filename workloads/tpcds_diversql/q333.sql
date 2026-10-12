WITH sales_store_ids AS (
    SELECT DISTINCT ss.ss_store_sk
    FROM store_sales ss
    JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
    WHERE d1.d_year = 2000
),
return_store_ids AS (
    SELECT DISTINCT sr.sr_store_sk
    FROM store_returns sr
    JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2000
),
sales_without_returns AS (
    SELECT ss_store_sk FROM sales_store_ids
    EXCEPT
    SELECT sr_store_sk FROM return_store_ids
)
SELECT
    s.s_store_id,
    d.d_year,
    sm.sm_carrier,
    w.w_warehouse_name,
    wp.wp_url,
    we.web_name,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    COUNT(DISTINCT cr.cr_reason_sk) AS distinct_return_reasons,
    COUNT(DISTINCT sr.sr_store_sk) AS distinct_return_stores,
    AVG(ss.ss_net_paid) AS avg_net_paid,
    MIN(ss.ss_net_paid) AS min_net_paid,
    MAX(ss.ss_net_paid) AS max_net_paid,
    COUNT(*) AS sales_cnt
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_returned_time_sk = t.t_time_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_return_time_sk = t.t_time_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
JOIN web_site we ON we.web_open_date_sk = d.d_date_sk
-- additional required joins to satisfy all tables
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d.d_year = 2000
  AND s.s_state = 'CA'
  AND sm.sm_carrier = 'UPS'
  AND w.w_zip = '36098'
  AND s.s_store_sk IN (SELECT ss_store_sk FROM sales_without_returns)
  AND NOT EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_ticket_number = ss.ss_ticket_number
    )
GROUP BY
    s.s_store_id,
    d.d_year,
    sm.sm_carrier,
    w.w_warehouse_name,
    wp.wp_url,
    we.web_name
ORDER BY total_catalog_return_amount DESC
OFFSET 10 LIMIT 20

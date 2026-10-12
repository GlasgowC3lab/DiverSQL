-- goal: Summarize catalog return performance by call center, ship mode, return year and catalog page type, demonstrating deep joins, scalar subquery filter, and a global row number
WITH
    -- re‑use the date dimension under several aliases to satisfy the 9‑join requirement
    d_ret AS (SELECT d_date_sk, d_year FROM date_dim),
    d_cc_open AS (SELECT d_date_sk, d_year FROM date_dim),
    d_cc_close AS (SELECT d_date_sk, d_year FROM date_dim),
    d_cp_start AS (SELECT d_date_sk, d_year FROM date_dim),
    d_cp_end AS (SELECT d_date_sk, d_year FROM date_dim)
SELECT
    cc.cc_name,
    sm.sm_type,
    d_ret.d_year            AS return_year,
    cp.cp_type,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_tax)    AS total_return_tax,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    ROW_NUMBER() OVER (ORDER BY SUM(cr.cr_return_amount) DESC) AS rn
FROM catalog_returns cr
JOIN call_center cc            ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm               ON cr.cr_ship_mode_sk   = sm.sm_ship_mode_sk
JOIN catalog_page cp            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN d_ret                      ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN d_cc_open                  ON cc.cc_open_date_sk    = d_cc_open.d_date_sk
JOIN d_cc_close                 ON cc.cc_closed_date_sk  = d_cc_close.d_date_sk
JOIN d_cp_start                 ON cp.cp_start_date_sk   = d_cp_start.d_date_sk
JOIN d_cp_end                   ON cp.cp_end_date_sk     = d_cp_end.d_date_sk
JOIN customer_demographics cd_ret ON cr.cr_refunded_cdemo_sk = cd_ret.cd_demo_sk
JOIN household_demographics hd_ret ON cr.cr_refunded_hdemo_sk = hd_ret.hd_demo_sk
JOIN web_page wp                ON wp.wp_creation_date_sk = d_cc_open.d_date_sk
WHERE cr.cr_return_amount > (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = 2452555
      )
GROUP BY
    cc.cc_name,
    sm.sm_type,
    d_ret.d_year,
    cp.cp_type
ORDER BY total_return_amount DESC
LIMIT 100

WITH
    agg_returns AS (
        SELECT
            cr_returned_date_sk,
            COUNT(*) AS cnt_returns,
            SUM(cr_return_amount) AS sum_return_amount
        FROM catalog_returns
        GROUP BY cr_returned_date_sk
    ),
    page_dates AS (
        SELECT
            cp.cp_catalog_page_sk,
            MIN(d.d_date) AS page_start_date,
            MAX(d.d_date) AS page_end_date
        FROM catalog_page cp
        JOIN date_dim d
            ON cp.cp_start_date_sk = d.d_date_sk
        GROUP BY cp.cp_catalog_page_sk
    ),
    ws_dates AS (
        SELECT
            ws.web_site_sk,
            ws.web_name,
            d.d_date AS open_date
        FROM web_site ws
        JOIN date_dim d
            ON ws.web_open_date_sk = d.d_date_sk
    ),
    promo_dates AS (
        SELECT
            p.p_promo_sk,
            p.p_promo_name,
            d.d_date AS promo_start_date
        FROM promotion p
        JOIN date_dim d
            ON p.p_start_date_sk = d.d_date_sk
    ),
    diff_dates AS (
        SELECT cr_returned_date_sk FROM catalog_returns
        EXCEPT
        SELECT cp_start_date_sk FROM catalog_page
    )
SELECT
    dr.d_year,
    dr.d_month_seq,
    agg.cnt_returns,
    agg.sum_return_amount,
    ca_refunded.ca_state            AS refunded_state,
    ca_returning.ca_state           AS returning_state,
    sm.sm_code,
    COALESCE(wd.web_name, 'UNKNOWN') AS web_name,
    pd.p_promo_name                 AS promo_name,
    (
        SELECT COUNT(*)
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = dr.d_date_sk
    )                               AS total_returns_on_date,
    (
        SELECT AVG(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_start_date_sk = dr.d_date_sk
    )                               AS avg_promo_cost,
    CASE WHEN dr.d_date_sk IN (SELECT cr_returned_date_sk FROM diff_dates) THEN 1 ELSE 0 END AS is_unique_return_date
FROM agg_returns agg
JOIN date_dim dr
    ON dr.d_date_sk = agg.cr_returned_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = agg.cr_returned_date_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN page_dates pd_page
    ON cp.cp_catalog_page_sk = pd_page.cp_catalog_page_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
FULL OUTER JOIN ws_dates wd
    ON wd.open_date = dr.d_date
FULL OUTER JOIN promo_dates pd
    ON pd.promo_start_date = dr.d_date
WHERE NOT EXISTS (
    SELECT 1
    FROM ship_mode sm2
    WHERE sm2.sm_ship_mode_sk = cr.cr_ship_mode_sk
      AND TRIM(sm2.sm_code) = 'AIR'
)
GROUP BY
    dr.d_year,
    dr.d_month_seq,
    agg.cnt_returns,
    agg.sum_return_amount,
    ca_refunded.ca_state,
    ca_returning.ca_state,
    sm.sm_code,
    wd.web_name,
    pd.p_promo_name,
    dr.d_date_sk
ORDER BY
    dr.d_year DESC,
    dr.d_month_seq ASC,
    agg.sum_return_amount DESC
LIMIT 100

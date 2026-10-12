SELECT
    cp.cp_department,
    s.s_state,
    d_cp_start.d_year AS catalog_start_year,
    d_cp_end.d_year AS catalog_end_year,
    CASE
        WHEN d_store_closed.d_date BETWEEN d_cp_start.d_date AND d_cp_end.d_date THEN 'ClosedDuringCatalog'
        ELSE 'OpenDuringCatalog'
    END AS store_closed_status,
    COUNT(DISTINCT ss.ss_ticket_number) AS ticket_cnt,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_page_cnt,
    MIN(d_wp_access.d_date) AS earliest_access_date,
    MAX(d_wp_access.d_date) AS latest_access_date
FROM catalog_page cp
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_cp_end.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_cp_end.d_date >= d_cp_start.d_date
GROUP BY
    cp.cp_department,
    s.s_state,
    d_cp_start.d_year,
    d_cp_end.d_year,
    CASE
        WHEN d_store_closed.d_date BETWEEN d_cp_start.d_date AND d_cp_end.d_date THEN 'ClosedDuringCatalog'
        ELSE 'OpenDuringCatalog'
    END
HAVING COUNT(DISTINCT ss.ss_ticket_number) > 5
ORDER BY total_profit DESC
LIMIT 100

WITH
    cs_pre AS (
        SELECT
            cs.cs_warehouse_sk,
            cs.cs_call_center_sk,
            cs.cs_ship_mode_sk,
            cs.cs_catalog_page_sk,
            SUM(cs.cs_net_paid) AS total_sales,
            SUM(cs.cs_ext_discount_amt) AS total_discount,
            COUNT(*) AS sales_cnt
        FROM
            catalog_sales cs
        TABLESAMPLE BERNOULLI (10)
        WHERE
            cs.cs_sold_date_sk BETWEEN 2450815 AND 2451170
            AND cs.cs_quantity > 1
            AND cs.cs_net_paid > 0
        GROUP BY
            cs.cs_warehouse_sk,
            cs.cs_call_center_sk,
            cs.cs_ship_mode_sk,
            cs.cs_catalog_page_sk
    ),
    cr_pre AS (
        SELECT
            cr.cr_warehouse_sk,
            cr.cr_reason_sk,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt
        FROM
            catalog_returns cr
        WHERE
            cr.cr_return_quantity > 0
            AND cr.cr_return_amount > 0
            AND cr.cr_fee < 100
        GROUP BY
            cr.cr_warehouse_sk,
            cr.cr_reason_sk
    ),
    first_select AS (
        SELECT
            w.w_warehouse_sk,
            w.w_warehouse_name,
            cc.cc_name AS call_center_name,
            sm.sm_carrier,
            r.r_reason_desc AS reason_desc,
            cs_pre.total_sales,
            cs_pre.total_discount,
            cs_pre.sales_cnt,
            cr_pre.total_return_amount,
            cr_pre.return_cnt,
            (
                SELECT SUM(ws.ws_net_paid)
                FROM web_sales ws
                WHERE ws.ws_warehouse_sk = w.w_warehouse_sk
                  AND ws.ws_quantity >= 2
                  AND ws.ws_net_paid > 0
            ) AS web_sales_total_net_paid
        FROM
            cs_pre
            JOIN call_center cc ON cs_pre.cs_call_center_sk = cc.cc_call_center_sk
            JOIN ship_mode sm ON cs_pre.cs_ship_mode_sk = sm.sm_ship_mode_sk
            FULL OUTER JOIN catalog_returns cr ON cs_pre.cs_warehouse_sk = cr.cr_warehouse_sk
            JOIN cr_pre ON cr.cr_warehouse_sk = cr_pre.cr_warehouse_sk
                           AND cr.cr_reason_sk = cr_pre.cr_reason_sk
            JOIN warehouse w ON cs_pre.cs_warehouse_sk = w.w_warehouse_sk
            LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
            LEFT JOIN catalog_page cp ON cs_pre.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE
            cc.cc_state = 'CA'
            AND sm.sm_type = 'AIR'
            AND w.w_state = 'CA'
            AND w.w_gmt_offset BETWEEN -8.00 AND -5.00
            AND cc.cc_employees > 100
            AND cc.cc_sq_ft > 20000
            AND cp.cp_description LIKE '%Natural%'
    ),
    ws_pre AS (
        SELECT
            ws.ws_warehouse_sk,
            ws.ws_ship_mode_sk,
            SUM(ws.ws_net_paid) AS total_sales,
            COUNT(*) AS sales_cnt
        FROM
            web_sales ws
        WHERE
            ws.ws_sold_date_sk BETWEEN 2450815 AND 2451170
            AND ws.ws_quantity > 1
            AND ws.ws_net_paid > 0
        GROUP BY
            ws.ws_warehouse_sk,
            ws.ws_ship_mode_sk
    ),
    second_select AS (
        SELECT
            w.w_warehouse_sk,
            w.w_warehouse_name,
            CAST(NULL AS varchar) AS call_center_name,
            sm.sm_carrier,
            CAST(NULL AS varchar) AS reason_desc,
            ws_pre.total_sales,
            CAST(NULL AS decimal(7,2)) AS total_discount,
            ws_pre.sales_cnt,
            CAST(NULL AS decimal(7,2)) AS total_return_amount,
            CAST(NULL AS integer) AS return_cnt,
            (
                SELECT SUM(ws2.ws_net_paid)
                FROM web_sales ws2
                WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk
                  AND ws2.ws_quantity >= 2
                  AND ws2.ws_net_paid > 0
            ) AS web_sales_total_net_paid
        FROM
            ws_pre
            JOIN ship_mode sm ON ws_pre.ws_ship_mode_sk = sm.sm_ship_mode_sk
            JOIN warehouse w ON ws_pre.ws_warehouse_sk = w.w_warehouse_sk
        WHERE
            sm.sm_carrier = 'AIRBORNE'
            AND w.w_state = 'CA'
            AND w.w_gmt_offset BETWEEN -8.00 AND -5.00
    ),
    union_all AS (
        SELECT * FROM first_select
        UNION
        SELECT * FROM second_select
    ),
    ranked AS (
        SELECT
            ua.*,
            ROW_NUMBER() OVER (PARTITION BY ua.w_warehouse_name ORDER BY ua.total_sales DESC) AS rn
        FROM union_all ua
    )
SELECT
    r.w_warehouse_sk,
    r.w_warehouse_name,
    r.call_center_name,
    r.sm_carrier,
    r.reason_desc,
    r.total_sales,
    r.total_discount,
    r.sales_cnt,
    r.total_return_amount,
    r.return_cnt,
    r.web_sales_total_net_paid
FROM ranked r
WHERE r.rn <= 5
ORDER BY r.w_warehouse_name, r.total_sales DESC
LIMIT 100

WITH refunded_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_returned_time_sk,
        cr.cr_warehouse_sk,
        cr.cr_call_center_sk,
        cr.cr_refunded_addr_sk
    FROM catalog_returns cr
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    cc.cc_name,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(s.suite_num) AS avg_suite_number,
    COUNT(*) AS return_count
FROM refunded_returns fr
JOIN warehouse w
    ON fr.cr_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc
    ON fr.cr_call_center_sk = cc.cc_call_center_sk
JOIN customer_address ca
    ON fr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN time_dim td
    ON fr.cr_returned_time_sk = td.t_time_sk
LEFT JOIN LATERAL (
    SELECT CAST(regexp_extract(ca.ca_suite_number, '\\d+') AS integer) AS suite_num
) AS s
    ON true
WHERE w.w_warehouse_name LIKE '%New%'
  AND regexp_like(cc.cc_name, 'Center')
  AND td.t_hour >= 12
  AND s.suite_num IS NOT NULL
GROUP BY w.w_warehouse_id, w.w_warehouse_name, cc.cc_name
ORDER BY total_return_amount DESC
LIMIT 100

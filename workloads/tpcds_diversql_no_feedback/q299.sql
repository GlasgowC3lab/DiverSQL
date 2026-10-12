SELECT
    w.w_warehouse_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS returns_cnt
FROM catalog_returns cr
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE w.w_gmt_offset = -5.00
  AND cr.cr_fee > 20.00
GROUP BY w.w_warehouse_name
ORDER BY total_return_amount DESC

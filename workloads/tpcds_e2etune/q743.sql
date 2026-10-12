SELECT
    w.w_country,
    w.w_state,
    w.w_warehouse_name,
    COUNT(cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_fee) AS total_fee,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(cr.cr_net_loss) AS total_net_loss,
    ROUND(SUM(cr.cr_return_amount) / NULLIF(w.w_warehouse_sq_ft, 0), 4) AS return_per_sqft,
    ROW_NUMBER() OVER (PARTITION BY w.w_country ORDER BY SUM(cr.cr_return_amount) DESC) AS country_warehouse_rank
FROM catalog_returns cr
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE cr.cr_fee > 20
  AND cr.cr_return_amount >= 100
  AND cr.cr_item_sk IN (202837, 256550, 239066)
  AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2455000
GROUP BY
    w.w_country,
    w.w_state,
    w.w_warehouse_name,
    w.w_warehouse_sq_ft
HAVING COUNT(cr.cr_order_number) > 5
ORDER BY total_return_amount DESC
LIMIT 50

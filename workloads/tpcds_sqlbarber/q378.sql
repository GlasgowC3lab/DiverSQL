SELECT i.inv_item_sk,
       i.inv_warehouse_sk,
       i.inv_quantity_on_hand,
       i.inv_quantity_on_hand * 0.9 AS adjusted_quantity,
       CASE WHEN i.inv_quantity_on_hand > 541 THEN 'High' ELSE 'Low' END AS quantity_level,
       d.d_date,
       d.d_year,
       d.d_month_seq,
       d.d_day_name,
       concat(d.d_day_name, ' ', cast(d.d_month_seq AS varchar)) AS day_month_desc,
       CASE WHEN d.d_weekend = 'Y' THEN 1 ELSE 0 END AS is_weekend,
       (d.d_year - d.d_month_seq) AS year_minus_month
FROM inventory i
JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
WHERE d.d_year = 1939 AND d.d_month_seq = 39

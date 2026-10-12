SELECT
    cp.cp_department,
    sm.sm_type,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_net_profit) AS avg_profit
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cp.cp_department = 'DEPARTMENT'
  AND sm.sm_type = 'REGULAR                       '
  AND cs.cs_sold_date_sk BETWEEN 2450822 AND 2450839
GROUP BY cp.cp_department, sm.sm_type
ORDER BY total_sales DESC

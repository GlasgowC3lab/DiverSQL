SELECT cs.cs_sold_date_sk,
       cs.cs_quantity,
       cs.cs_sales_price,
       cs.cs_quantity * cs.cs_sales_price AS total_sales,
       CASE WHEN cs.cs_quantity > 63 THEN 'Large Order' ELSE 'Regular Order' END AS order_type,
       td.t_hour,
       td.t_am_pm,
       CASE WHEN td.t_hour BETWEEN 22 AND 11 THEN 'Peak' ELSE 'Off-Peak' END AS time_category
FROM catalog_sales cs
JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
WHERE cs.cs_net_paid > 3115.63

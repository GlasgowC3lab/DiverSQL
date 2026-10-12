SELECT
    cp.cp_department,
    p.p_promo_name,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(*) AS sales_count
FROM catalog_sales cs
JOIN date_dim dsale
    ON cs.cs_sold_date_sk = dsale.d_date_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE dsale.d_year = 2001
  AND cp.cp_department = 'DEPARTMENT'
  AND cd.cd_marital_status = 'M'
  AND cd.cd_education_status = 'College'
  AND cs.cs_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
GROUP BY cp.cp_department, p.p_promo_name
HAVING SUM(cs.cs_ext_sales_price) > 10000
ORDER BY total_net_profit DESC
LIMIT 100

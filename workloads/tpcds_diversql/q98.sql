WITH sales_data AS (
    SELECT
        cc.cc_name,
        cp.cp_description,
        cp.cp_type,
        sm.sm_type,
        cs.cs_net_profit,
        regexp_extract(cp.cp_description, '(\\d{4})') AS extracted_year
    FROM catalog_sales cs
    INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(cp.cp_description, 'discount')
      AND cc.cc_name LIKE 'C%'
      AND cp.cp_type LIKE '%A%'
      AND sm.sm_type LIKE '%AIR%'
)
SELECT
    cc_name,
    extracted_year,
    COUNT(*) AS sales_cnt,
    SUM(cs_net_profit) AS total_profit,
    CASE WHEN SUM(cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
FROM sales_data
GROUP BY cc_name, extracted_year
ORDER BY total_profit DESC
LIMIT 100

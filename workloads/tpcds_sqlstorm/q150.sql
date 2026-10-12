SELECT
   d.d_year,
   d.d_month_seq,
   COUNT(*) AS total_sales,
   SUM(cs.cs_net_paid) AS total_net_paid,
   SUM(LENGTH(cc.cc_name)) AS total_call_center_name_len,
   SUM(LENGTH(REGEXP_REPLACE(i.i_product_name, '[^A-Za-z]', ''))) AS total_alpha_product_name_len,
   APPROX_DISTINCT(REGEXP_REPLACE(i.i_product_name, '\\s+', '')) AS approx_distinct_product_names,
   COUNT(DISTINCT CONCAT_WS(' ', LOWER(cc.cc_name), UPPER(i.i_brand), SUBSTR(i.i_product_name, 1, 5))) AS unique_cc_brand_product_combinations,
   SUM(LENGTH(REGEXP_REPLACE(CONCAT(i.i_product_name, ' ', cp.cp_description, ' ', p.p_promo_name), '\\s+', ''))) AS total_combined_string_len,
   AVG(LENGTH(TRIM(p.p_promo_name))) AS avg_promo_name_len,
   SUM(CASE WHEN REGEXP_LIKE(p.p_promo_name, 'sale') THEN 1 ELSE 0 END) AS promo_name_contains_sale_cnt,
   SUM(LENGTH(REGEXP_REPLACE(cc.cc_manager, '[^A-Za-z]', ''))) AS total_manager_alpha_len,
   COUNT(DISTINCT CONCAT(SUBSTR(UPPER(i.i_color), 1, 1), SUBSTR(UPPER(i.i_size), 1, 1))) AS unique_color_size_initials
FROM
   catalog_sales cs
JOIN
   call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN
   item i ON cs.cs_item_sk = i.i_item_sk
JOIN
   date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN
   promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN
   catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
   d.d_year BETWEEN 1999 AND 2002
GROUP BY
   d.d_year,
   d.d_month_seq
ORDER BY
   d.d_year,
   d.d_month_seq

WITH per_sale AS (
  SELECT
    d.d_year AS d_year,
    i.i_category AS i_category,
    cs.cs_ext_sales_price AS cs_ext_sales_price,
    LENGTH(i.i_product_name) AS product_name_len,
    LENGTH(REPLACE(i.i_product_name, ' ', '')) AS product_name_no_spaces_len,
    LENGTH(REGEXP_REPLACE(i.i_product_name, '[^A-Za-z]', '')) AS product_name_alpha_len,
    CARDINALITY(array_distinct(REGEXP_SPLIT(lower(REGEXP_REPLACE(i.i_item_desc, '[^a-zA-Z0-9 ]', '')), '\\s+'))) AS unique_word_cnt,
    CASE WHEN lower(i.i_color) = 'red' THEN cs.cs_ext_sales_price ELSE 0 END AS red_color_sales,
    LENGTH(CONCAT(i.i_brand, ' ', i.i_product_name)) AS brand_product_len,
    LENGTH(TRIM(i.i_manufact)) AS manufact_len,
    LENGTH(SUBSTRING(i.i_item_desc FROM 1 FOR 20)) AS desc_prefix_len,
    POSITION('blue' IN lower(i.i_item_desc)) AS pos_blue,
    LENGTH(REGEXP_EXTRACT(i.i_item_desc, '(\\d{4})')) AS extracted_year_len,
    LENGTH(REGEXP_REPLACE(i.i_item_desc, '(\\s+)', ' ')) AS normalized_space_len
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE i.i_item_desc IS NOT NULL
)
SELECT
  d_year,
  i_category,
  COUNT(*) AS sales_transactions,
  SUM(cs_ext_sales_price) AS total_sales,
  AVG(product_name_len) AS avg_product_name_len,
  AVG(product_name_no_spaces_len) AS avg_product_name_no_spaces_len,
  AVG(product_name_alpha_len) AS avg_product_name_alpha_len,
  AVG(unique_word_cnt) AS avg_unique_word_cnt,
  SUM(red_color_sales) AS total_red_color_sales,
  AVG(brand_product_len) AS avg_brand_product_len,
  AVG(manufact_len) AS avg_manufact_len,
  AVG(desc_prefix_len) AS avg_desc_prefix_len,
  AVG(pos_blue) AS avg_pos_blue,
  AVG(extracted_year_len) AS avg_extracted_year_len,
  AVG(normalized_space_len) AS avg_normalized_space_len
FROM per_sale
GROUP BY d_year, i_category
ORDER BY d_year, i_category

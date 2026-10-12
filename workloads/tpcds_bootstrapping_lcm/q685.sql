SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  cd.cd_gender,
  cd.cd_marital_status,
  cd.cd_education_status,
  ds_first_sales.d_date          AS first_sales_date,
  ds_first_shipto.d_date         AS first_shipto_date,
  ds_last_review.d_date          AS last_review_date,
  s.s_store_name,
  s.s_city,
  s.s_state,
  COUNT(DISTINCT wp.wp_web_page_id)              AS web_pages_count,
  MIN(d_creation.d_date)                         AS earliest_page_creation,
  MAX(d_access.d_date)                           AS latest_page_access,
  SUM(CASE WHEN wp.wp_autogen_flag = 'Y' THEN 1 ELSE 0 END) AS auto_generated_pages,
  AVG(cd.cd_purchase_estimate)                  AS avg_purchase_estimate
FROM customer c
JOIN customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN date_dim ds_first_sales
  ON c.c_first_sales_date_sk = ds_first_sales.d_date_sk
JOIN date_dim ds_first_shipto
  ON c.c_first_shipto_date_sk = ds_first_shipto.d_date_sk
JOIN date_dim ds_last_review
  ON c.c_last_review_date = ds_last_review.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = ds_first_sales.d_date_sk
JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_creation
  ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
  ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE cd.cd_gender = 'F'
GROUP BY
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  cd.cd_gender,
  cd.cd_marital_status,
  cd.cd_education_status,
  ds_first_sales.d_date,
  ds_first_shipto.d_date,
  ds_last_review.d_date,
  s.s_store_name,
  s.s_city,
  s.s_state
ORDER BY web_pages_count DESC, c.c_customer_id
LIMIT 100

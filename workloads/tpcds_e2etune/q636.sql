WITH wp_customer AS (
  SELECT 
    wp.wp_web_page_sk,
    wp.wp_type,
    wp.wp_char_count,
    wp.wp_link_count,
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status
  FROM web_page wp
  JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  WHERE wp.wp_type IN ('article', 'product')
    AND wp.wp_access_date_sk >= 20200101
),

agg AS (
  SELECT
    cd_gender,
    cd_marital_status,
    wp_type,
    COUNT(DISTINCT wp_web_page_sk) AS distinct_pages,
    COUNT(*) AS total_visits,
    AVG(wp_char_count) AS avg_char_count,
    SUM(wp_link_count) AS total_links,
    COUNT(DISTINCT c_customer_id) AS distinct_customers
  FROM wp_customer
  GROUP BY cd_gender, cd_marital_status, wp_type
  HAVING COUNT(*) > 100
)
SELECT
  cd_gender,
  cd_marital_status,
  wp_type,
  distinct_pages,
  total_visits,
  avg_char_count,
  total_links,
  distinct_customers,
  RANK() OVER (ORDER BY avg_char_count DESC) AS char_count_rank
FROM agg
ORDER BY total_links DESC
LIMIT 50

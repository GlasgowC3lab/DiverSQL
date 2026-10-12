WITH wp_metrics AS (
  SELECT
    wp_customer_sk,
    SUM(wp_image_count) AS total_images,
    AVG(wp_char_count) AS avg_char_count
  FROM web_page
  WHERE wp_type = 'Product'
  GROUP BY wp_customer_sk
),
agg AS (
  SELECT
    s.s_country,
    s.s_state,
    s.s_city,
    cr.cr_returning_customer_sk AS customer_sk,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    wm.total_images,
    wm.avg_char_count
  FROM catalog_returns cr
  JOIN wp_metrics wm ON cr.cr_returning_customer_sk = wm.wp_customer_sk
  JOIN store s ON cr.cr_warehouse_sk = s.s_store_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2451545 AND 2451555
    AND s.s_country = 'United States'
  GROUP BY s.s_country, s.s_state, s.s_city, cr.cr_returning_customer_sk, wm.total_images, wm.avg_char_count
  HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
  a.s_country,
  a.s_state,
  a.s_city,
  a.customer_sk,
  a.num_returns,
  a.total_return_amount,
  a.avg_return_quantity,
  a.total_images,
  a.avg_char_count,
  RANK() OVER (PARTITION BY a.s_country ORDER BY a.total_return_amount DESC) AS country_return_rank
FROM agg a
ORDER BY a.total_return_amount DESC
LIMIT 100

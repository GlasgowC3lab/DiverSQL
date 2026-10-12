WITH filtered_dates AS (
    SELECT *
    FROM date_dim
    WHERE d_year BETWEEN 2015 AND 2020
)
SELECT
    d.d_date AS store_closed_date,
    d.d_year,
    d.d_month_seq,
    store.s_store_id,
    store.s_store_name,
    store.s_state,
    store.s_city,
    store.s_number_employees,
    web_site.web_site_id,
    web_site.web_name,
    web_site.web_state,
    web_site.web_country,
    d_close.d_date AS site_close_date,
    date_diff('day', d.d_date, d_close.d_date) AS site_open_to_close_days,
    web_page.wp_web_page_id,
    web_page.wp_url,
    web_page.wp_type,
    COUNT(DISTINCT web_page.wp_customer_sk) AS unique_customers,
    SUM(web_page.wp_image_count) AS total_images,
    AVG(web_page.wp_char_count) AS avg_char_count
FROM store
JOIN filtered_dates d
  ON store.s_closed_date_sk = d.d_date_sk
JOIN web_site
  ON web_site.web_open_date_sk = d.d_date_sk
JOIN date_dim d_close
  ON web_site.web_close_date_sk = d_close.d_date_sk
JOIN web_page
  ON web_page.wp_creation_date_sk = d.d_date_sk
   AND web_page.wp_access_date_sk = d.d_date_sk
WHERE store.s_state = 'CA'
  AND web_site.web_country = 'United States'
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq,
    store.s_store_id,
    store.s_store_name,
    store.s_state,
    store.s_city,
    store.s_number_employees,
    web_site.web_site_id,
    web_site.web_name,
    web_site.web_state,
    web_site.web_country,
    d_close.d_date,
    web_page.wp_web_page_id,
    web_page.wp_url,
    web_page.wp_type
HAVING COUNT(DISTINCT web_page.wp_customer_sk) > 10
ORDER BY d.d_date DESC
LIMIT 100

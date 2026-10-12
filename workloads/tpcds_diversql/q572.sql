SELECT
  wp_url,
  wp_type,
  wp_image_count
FROM
  tpcds.web_page
WHERE
  wp_image_count > 3
  AND wp_rec_end_date = DATE '2000-09-02'
LIMIT 100

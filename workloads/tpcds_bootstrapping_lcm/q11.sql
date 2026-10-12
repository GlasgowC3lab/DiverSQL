SELECT
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_page_number,
    cp.cp_description,
    d_end.d_year AS end_year,
    d_start.d_year AS start_year,
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_closed.d_year AS store_closed_year,
    sr.sr_return_amt,
    sr.sr_return_quantity,
    sr.sr_fee,
    sr.sr_return_tax,
    sr.sr_return_ship_cost,
    (sr.sr_return_amt * sr.sr_return_quantity) AS total_return_amount,
    SUM(sr.sr_return_amt * sr.sr_return_quantity) OVER (PARTITION BY cp.cp_department) AS dept_total_return,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY (sr.sr_return_amt * sr.sr_return_quantity) DESC) AS dept_return_rank,
    wp.wp_url,
    wp.wp_type,
    wp.wp_image_count,
    d_wp_access.d_year AS wp_access_year
FROM catalog_page cp
JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d_end.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_end.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE cp.cp_type = 'Catalog'
  AND s.s_state = 'CA'
  AND d_end.d_year = 2023
ORDER BY total_return_amount DESC
LIMIT 100

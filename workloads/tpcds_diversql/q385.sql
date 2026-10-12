WITH cte_date AS (
    SELECT d_date_sk, d_year, d_quarter_name, d_holiday
    FROM date_dim
    WHERE d_year = 2000
      AND d_quarter_name = '1901Q1'
),
catalog_filtered AS (
    SELECT cp_catalog_page_sk,
           cp_catalog_page_id,
           cp_start_date_sk,
           cp_department,
           cp_catalog_number
    FROM catalog_page
    WHERE cp_department = 'Electronics'
      AND cp_catalog_page_sk IN (
          SELECT wp_web_page_sk
          FROM web_page
          WHERE wp_char_count > 3000
      )
),
store_filtered AS (
    SELECT s_store_sk,
           s_store_name,
           s_state,
           s_hours,
           s_closed_date_sk
    FROM store
    WHERE s_state = 'CA'
      AND s_hours = '8AM-4PM'
),
web_filtered AS (
    SELECT wp_web_page_sk,
           wp_char_count,
           wp_creation_date_sk,
           wp_access_date_sk
    FROM web_page
    WHERE wp_access_date_sk IN (2452596, 2452629)
      AND wp_char_count BETWEEN 3000 AND 5000
),
intersect_keys AS (
    SELECT wp_web_page_sk FROM web_page WHERE wp_char_count > 4000
    INTERSECT
    SELECT wp_web_page_sk FROM web_page WHERE wp_access_date_sk = 2452596
),
except_keys AS (
    SELECT wp_web_page_sk FROM web_page WHERE wp_char_count > 4000
    EXCEPT
    SELECT wp_web_page_sk FROM web_page WHERE wp_char_count < 2000
)
SELECT
    s.s_store_name,
    s.s_state,
    s.s_hours,
    COUNT(DISTINCT c.cp_catalog_page_sk) AS catalog_page_cnt,
    SUM(w.wp_char_count) AS total_char_count,
    AVG(w.wp_char_count) AS avg_char_count,
    MIN(w.wp_char_count) AS min_char_count,
    MAX(w.wp_char_count) AS max_char_count
FROM catalog_filtered c
JOIN cte_date d ON c.cp_start_date_sk = d.d_date_sk
JOIN store_filtered s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_filtered w ON w.wp_creation_date_sk = d.d_date_sk
WHERE c.cp_catalog_page_sk IN (SELECT wp_web_page_sk FROM intersect_keys)
  AND w.wp_web_page_sk NOT IN (SELECT wp_web_page_sk FROM except_keys)
GROUP BY s.s_store_name, s.s_state, s.s_hours
ORDER BY total_char_count DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

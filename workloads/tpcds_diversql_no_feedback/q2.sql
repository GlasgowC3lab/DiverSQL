SELECT
    wp_type,
    COUNT(*) AS page_count,
    AVG(wp_char_count) AS avg_char_count
FROM tpcds.web_page
WHERE wp_autogen_flag = 'N'
  AND wp_access_date_sk BETWEEN 2452565 AND 2452596
GROUP BY wp_type
ORDER BY page_count DESC

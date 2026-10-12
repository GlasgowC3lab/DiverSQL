SELECT
    cp.cp_department,
    cp.cp_type,
    s.s_state,
    d_end.d_year,
    CASE WHEN d_end.d_year < 2020 THEN 'Pre2020' ELSE '2020+' END AS year_bucket,
    d_start.d_quarter_name AS start_quarter,
    wp.wp_type,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT wp.wp_url) AS distinct_url_cnt,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_catalog_pages
FROM
    catalog_page cp
    JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_end.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_create ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
WHERE
    d_end.d_year >= 2015
    AND s.s_state IS NOT NULL
GROUP BY
    cp.cp_department,
    cp.cp_type,
    s.s_state,
    d_end.d_year,
    CASE WHEN d_end.d_year < 2020 THEN 'Pre2020' ELSE '2020+' END,
    d_start.d_quarter_name,
    wp.wp_type
HAVING
    SUM(wr.wr_return_amt) > 1000
ORDER BY
    total_return_amt DESC
LIMIT 100

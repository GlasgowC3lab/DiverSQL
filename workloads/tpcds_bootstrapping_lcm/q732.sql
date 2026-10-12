SELECT
    s.s_store_id,
    d_sold.d_current_month,
    d_sold.d_year,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_return_net_loss,
    AVG(wp.wp_image_count) AS avg_page_image_count,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    MIN(d_closed.d_current_month) AS store_closed_month,
    MAX(d_access.d_current_month) AS latest_page_access_month
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_sold.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_sold.d_year = 2002
  AND s.s_state = 'TX'
GROUP BY s.s_store_id, d_sold.d_current_month, d_sold.d_year
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales_amount DESC
LIMIT 100

SELECT
    d.d_year,
    d.d_month_seq,
    s.s_state,
    s.s_city,
    w.w_warehouse_name,
    COUNT(DISTINCT cr.cr_order_number) AS total_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages,
    AVG(wp.wp_image_count) AS avg_image_count,
    SUM(wp.wp_char_count) AS total_char_count
FROM catalog_returns AS cr
JOIN date_dim AS d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse AS w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN store AS s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page AS wp
    ON wp.wp_creation_date_sk = d.d_date_sk
    AND wp.wp_access_date_sk = d.d_date_sk
WHERE d.d_year >= 2015
  AND s.s_country = 'United States'
  AND w.w_country = 'United States'
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_state,
    s.s_city,
    w.w_warehouse_name
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_net_loss DESC
LIMIT 100

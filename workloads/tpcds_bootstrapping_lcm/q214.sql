SELECT
    d.d_year,
    d.d_month_seq,
    s.s_state,
    wp.wp_type,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    COUNT(DISTINCT s.s_store_sk) AS distinct_stores,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    AVG(CASE WHEN cr.cr_return_quantity > 0 THEN cr.cr_return_amount / cr.cr_return_quantity END) AS avg_catalog_return_per_item,
    SUM(CASE WHEN wr.wr_return_quantity > 0 THEN wr.wr_return_amt / wr.wr_return_quantity ELSE 0 END) AS total_web_return_per_item,
    SUM(CASE WHEN wp.wp_type = 'product' THEN cr.cr_return_amount ELSE 0 END) AS product_catalog_return_amount,
    SUM(CASE WHEN wp.wp_type = 'advertisement' THEN wr.wr_return_amt ELSE 0 END) AS ad_web_return_amount
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = wr.wr_web_page_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND s.s_state IS NOT NULL
  AND wp.wp_type IS NOT NULL
GROUP BY d.d_year, d.d_month_seq, s.s_state, wp.wp_type
HAVING COUNT(*) > 10
ORDER BY total_catalog_net_loss DESC
LIMIT 100

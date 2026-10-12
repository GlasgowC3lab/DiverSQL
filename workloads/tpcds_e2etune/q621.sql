SELECT
    wp.wp_type,
    d_create.d_year,
    d_create.d_month_seq,
    COUNT(DISTINCT wp.wp_web_page_sk) AS pages_created,
    SUM(wp.wp_link_count) AS total_link_count,
    SUM(wp.wp_image_count) AS total_image_count,
    COUNT(DISTINCT wr.wr_returning_customer_sk) AS distinct_returning_customers,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
    SUM(wr.wr_fee) AS total_fees,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty
FROM web_returns wr
JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_create ON wp.wp_creation_date_sk = d_create.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_ret.d_year = 1902
  AND d_ret.d_fy_quarter_seq = 2
  AND d_create.d_year BETWEEN 1900 AND 1903
  AND d_access.d_year = 1902
  AND wp.wp_type IN ('product', 'article')
  AND wr.wr_return_amt > 0
GROUP BY wp.wp_type, d_create.d_year, d_create.d_month_seq
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100

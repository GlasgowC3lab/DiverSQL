SELECT
    d.d_year,
    d.d_month_seq,
    s.s_store_id,
    s.s_state,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    COUNT(DISTINCT wp.wp_web_page_id) AS num_pages,
    SUM(CASE WHEN wp.wp_type = 'product' THEN 1 ELSE 0 END) AS product_page_count,
    SUM(cr.cr_net_loss) / NULLIF(SUM(ss.ss_net_profit), 0) AS loss_to_profit_ratio
FROM
    date_dim d
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
                         AND ss.ss_store_sk = s.s_store_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
                      AND wp.wp_access_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2000 AND 2005
    AND s.s_state IN ('TX', 'CA', 'NY')
    AND wp.wp_type IS NOT NULL
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_store_id,
    s.s_state
HAVING
    SUM(ss.ss_net_profit) > 10000
ORDER BY
    d.d_year,
    d.d_month_seq,
    total_net_profit DESC
LIMIT 100

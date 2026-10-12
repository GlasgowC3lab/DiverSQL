SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sale.d_year,
    d_sale.d_month_seq,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    SUM(wr.wr_net_loss) AS total_return_loss,
    AVG(wp.wp_image_count) AS avg_image_count,
    MAX(wp.wp_char_count) AS max_char_count,
    MIN(wp.wp_char_count) AS min_char_count,
    d_return.d_date AS latest_return_date,
    d_creation.d_date AS page_creation_date,
    d_access.d_date AS page_access_date,
    d_closed.d_date AS store_closed_date
FROM store s
JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sale
    ON ss.ss_sold_date_sk = d_sale.d_date_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sale.d_date_sk
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = wr.wr_web_page_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_sale.d_year = 2022
  AND s.s_state = 'CA'
  AND wp.wp_type = 'product'
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sale.d_year,
    d_sale.d_month_seq,
    d_return.d_date,
    d_creation.d_date,
    d_access.d_date,
    d_closed.d_date
ORDER BY total_sales_amount DESC
LIMIT 100

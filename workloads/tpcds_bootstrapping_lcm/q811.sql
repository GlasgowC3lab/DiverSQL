SELECT
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year AS sale_year,
    d_sold.d_moy AS sale_month,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(ss.ss_net_paid) AS total_sales_net_paid,
    SUM(ss.ss_quantity) AS total_sales_quantity,
    SUM(ss.ss_ext_tax) AS total_sales_tax,
    SUM(ss.ss_net_profit) AS total_sales_net_profit,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    SUM(sr.sr_net_loss) AS total_return_net_loss,
    AVG(date_diff('day', d_sold.d_date, d_return.d_date)) AS avg_days_to_return,
    AVG(wp.wp_image_count) AS avg_page_image_count,
    AVG(wp.wp_char_count) AS avg_page_char_count,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_page_count,
    MAX(d_closed.d_date) AS store_closed_date,
    MIN(d_sold.d_date) AS earliest_sale_date,
    MAX(d_access.d_date) AS latest_page_access_date
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_moy

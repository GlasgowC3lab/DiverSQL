SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    d_sold.d_date AS sold_date,
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    s.s_state,
    d_store_closed.d_date AS store_closed_date,
    ss.ss_ticket_number,
    ss.ss_quantity,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    d_cp_end.d_date AS catalog_end_date,
    date_diff('day', d_sold.d_date, d_cp_end.d_date) AS days_between_sale_and_catalog_end,
    w.web_name,
    w.web_city,
    d_web_close.d_date AS web_close_date,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY ss.ss_ext_sales_price DESC) AS state_sales_rank
FROM store_sales ss
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sold.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN web_site w
    ON w.web_open_date_sk = d_sold.d_date_sk
JOIN date_dim d_web_close
    ON w.web_close_date_sk = d_web_close.d_date_sk
WHERE ss.ss_quantity > 0
ORDER BY state_sales_rank, cp.cp_catalog_page_id
LIMIT 100

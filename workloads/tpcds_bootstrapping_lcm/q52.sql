SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    cp.cp_catalog_page_number,
    ds_start.d_date AS catalog_start_date,
    ds_end.d_date AS catalog_end_date,
    s.s_store_id,
    s.s_state,
    ds_closed.d_date AS store_closed_date,
    ws.web_site_id,
    ws.web_state,
    ds_web_open.d_date AS website_open_date,
    ds_web_close.d_date AS website_close_date,
    ds_sold.d_date AS sold_date,
    SUM(ss.ss_ext_sales_price) AS total_ext_sales_price,
    SUM(ss.ss_quantity) AS total_quantity,
    AVG(ss.ss_ext_discount_amt) AS avg_ext_discount_amt,
    MAX(ss.ss_sales_price) AS max_sales_price
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim ds_sold ON ss.ss_sold_date_sk = ds_sold.d_date_sk
JOIN date_dim ds_closed ON s.s_closed_date_sk = ds_closed.d_date_sk
CROSS JOIN catalog_page cp
JOIN date_dim ds_start ON cp.cp_start_date_sk = ds_start.d_date_sk
JOIN date_dim ds_end ON cp.cp_end_date_sk = ds_end.d_date_sk
CROSS JOIN web_site ws
JOIN date_dim ds_web_open ON ws.web_open_date_sk = ds_web_open.d_date_sk
JOIN date_dim ds_web_close ON ws.web_close_date_sk = ds_web_close.d_date_sk
WHERE ds_sold.d_date BETWEEN ds_start.d_date AND ds_end.d_date
  AND ds_sold.d_date BETWEEN ds_web_open.d_date AND ds_web_close.d_date
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_department,
    cp.cp_catalog_page_number,
    ds_start.d_date,
    ds_end.d_date,
    s.s_store_id,
    s.s_state,
    ds_closed.d_date,
    ws.web_site_id,
    ws.web_state,
    ds_web_open.d_date,
    ds_web_close.d_date,
    ds_sold.d_date
ORDER BY total_ext_sales_price DESC
LIMIT 100

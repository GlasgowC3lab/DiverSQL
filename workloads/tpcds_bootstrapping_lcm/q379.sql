SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_department,
    d_cp_start.d_date AS cp_start_date,
    d_cp_end.d_date AS cp_end_date,
    p.p_promo_name,
    p.p_cost,
    d_promo_start.d_date AS promo_start_date,
    d_promo_end.d_date AS promo_end_date,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_store_closed.d_date AS store_closed_date,
    d_wr_returned.d_year AS return_year,
    d_wr_returned.d_month_seq AS return_month,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
FROM catalog_page cp
JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_cp_end.d_date_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_cp_end.d_date_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_cp_end.d_date_sk
JOIN date_dim d_wr_returned ON wr.wr_returned_date_sk = d_wr_returned.d_date_sk
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_department,
    d_cp_start.d_date,
    d_cp_end.d_date,
    p.p_promo_name,
    p.p_cost,
    d_promo_start.d_date,
    d_promo_end.d_date,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_store_closed.d_date,
    d_wr_returned.d_year,
    d_wr_returned.d_month_seq
ORDER BY total_return_amount DESC
LIMIT 100

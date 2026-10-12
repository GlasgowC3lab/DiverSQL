SELECT
    s.s_store_id,
    s.s_store_name,
    dr.d_year,
    dr.d_moy AS month,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(sr.sr_net_loss) - SUM(wr.wr_net_loss) AS net_loss_diff,
    AVG(sr.sr_return_quantity) AS avg_store_return_qty,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty,
    SUM(CASE WHEN c_sr.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_store_customers,
    SUM(CASE WHEN c_ret.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_returning_customers,
    MIN(d_ship.d_date) AS earliest_ship_date,
    MIN(d_sales.d_date) AS earliest_sales_date,
    MAX(d_review.d_date) AS latest_review_date,
    SUM(CASE WHEN d_closure.d_date IS NOT NULL AND dr.d_date > d_closure.d_date THEN 1 ELSE 0 END) AS returns_after_closure,
    COUNT(DISTINCT c_wr.c_customer_id) AS distinct_refunded_customers
FROM store s
JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = dr.d_date_sk
JOIN customer c_sr ON c_sr.c_customer_sk = sr.sr_customer_sk
JOIN customer c_wr ON c_wr.c_customer_sk = wr.wr_refunded_customer_sk
JOIN customer c_ret ON c_ret.c_customer_sk = wr.wr_returning_customer_sk
JOIN date_dim d_closure ON s.s_closed_date_sk = d_closure.d_date_sk
JOIN date_dim d_ship ON c_sr.c_first_shipto_date_sk = d_ship.d_date_sk
JOIN date_dim d_sales ON c_sr.c_first_sales_date_sk = d_sales.d_date_sk
JOIN date_dim d_review ON c_sr.c_last_review_date = d_review.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    dr.d_year,
    dr.d_moy
ORDER BY
    s.s_store_id,
    dr.d_year,
    dr.d_moy
LIMIT 100

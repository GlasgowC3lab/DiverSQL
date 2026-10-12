SELECT
    s.s_state,
    d_ret.d_year AS return_year,
    d_ret.d_moy AS return_month,
    c.c_birth_month,
    COUNT(*) AS total_return_transactions,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(sr.sr_store_credit) AS total_store_credit,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN sr.sr_fee > 0 THEN sr.sr_fee ELSE 0 END) AS total_fee,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    COUNT(DISTINCT sr.sr_item_sk) AS distinct_items_returned,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages_created,
    SUM(CASE WHEN d_store.d_year = d_ret.d_year THEN 1 ELSE 0 END) AS same_year_store_closed_count,
    SUM(CASE WHEN d_web.d_year = d_ret.d_year THEN 1 ELSE 0 END) AS web_pages_created_same_year,
    SUM(sr.sr_net_loss) AS total_net_loss
FROM store_returns sr
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN date_dim d_web
    ON wp.wp_creation_date_sk = d_web.d_date_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2020
GROUP BY s.s_state, d_ret.d_year, d_ret.d_moy, c.c_birth_month
ORDER BY total_return_amount DESC
LIMIT 100

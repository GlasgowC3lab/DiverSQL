SELECT
    st.s_store_id,
    st.s_store_name,
    st.s_city,
    st.s_state,
    dd_closed.d_year AS store_closed_year,
    dd_return.d_year AS return_year,
    dd_sold.d_year AS sold_year,
    dd_ship.d_year AS ship_year,
    dd_creation.d_year AS page_creation_year,
    dd_access.d_year AS page_access_year,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(date_diff('day', dd_sold.d_date, dd_ship.d_date)) AS avg_days_to_ship,
    AVG(date_diff('day', dd_sold.d_date, dd_return.d_date)) AS avg_days_to_return,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_return_loss,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    MAX(wp.wp_char_count) AS max_page_characters,
    MIN(wp.wp_char_count) AS min_page_characters
FROM store st
JOIN date_dim dd_closed
    ON st.s_closed_date_sk = dd_closed.d_date_sk
JOIN store_returns sr
    ON sr.sr_store_sk = st.s_store_sk
JOIN date_dim dd_return
    ON sr.sr_returned_date_sk = dd_return.d_date_sk
JOIN catalog_sales cs
    ON true
JOIN date_dim dd_sold
    ON cs.cs_sold_date_sk = dd_sold.d_date_sk
JOIN date_dim dd_ship
    ON cs.cs_ship_date_sk = dd_ship.d_date_sk
JOIN web_page wp
    ON true
JOIN date_dim dd_creation
    ON wp.wp_creation_date_sk = dd_creation.d_date_sk
JOIN date_dim dd_access
    ON wp.wp_access_date_sk = dd_access.d_date_sk
WHERE dd_sold.d_year = 2001
  AND st.s_state = 'CA'
GROUP BY
    st.s_store_id,
    st.s_store_name,
    st.s_city,
    st.s_state,
    dd_closed.d_year,
    dd_return.d_year,
    dd_sold.d_year,
    dd_ship.d_year,
    dd_creation.d_year,
    dd_access.d_year
ORDER BY total_sales DESC
LIMIT 100

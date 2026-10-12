SELECT
    cc.cc_company_name,
    cc.cc_state,
    d_sales.d_year AS sales_year,
    d_sales.d_month_seq AS sales_month,
    p.p_promo_name,
    st.s_store_name,
    st.s_state,
    st.s_city,
    d_store_closed.d_date AS store_closed_date,
    d_promo_start.d_date AS promo_start_date,
    COUNT(DISTINCT ss.ss_ticket_number) AS tickets_sold,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_quantity) AS avg_quantity,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(p.p_cost) AS total_promo_cost
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store st
    ON ss.ss_store_sk = st.s_store_sk
JOIN date_dim d_store_closed
    ON st.s_closed_date_sk = d_store_closed.d_date_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sales.d_date_sk
WHERE d_sales.d_year BETWEEN 2015 AND 2020
  AND st.s_state = 'CA'
GROUP BY
    cc.cc_company_name,
    cc.cc_state,
    d_sales.d_year,
    d_sales.d_month_seq,
    p.p_promo_name,
    st.s_store_name,
    st.s_state,
    st.s_city,
    d_store_closed.d_date,
    d_promo_start.d_date
HAVING SUM(ss.ss_ext_sales_price) > 50000
ORDER BY total_sales DESC
LIMIT 100

SELECT
    cc.cc_division,
    cc.cc_city,
    st.s_city AS store_city,
    d_cs.d_year,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets,
    SUM(cs.cs_net_paid_inc_tax) AS catalog_net_paid_inc_tax,
    SUM(ss.ss_net_paid_inc_tax) AS store_net_paid_inc_tax,
    SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) AS total_profit,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
    MAX(cs.cs_ext_discount_amt) AS max_catalog_discount,
    MIN(ss.ss_coupon_amt) AS min_store_coupon
FROM call_center cc
JOIN catalog_sales cs
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc
    ON cc.cc_closed_date_sk = d_cc.d_date_sk
JOIN date_dim d_cs
    ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_cs.d_date_sk
JOIN store st
    ON ss.ss_store_sk = st.s_store_sk
JOIN date_dim d_store_closed
    ON st.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_cs.d_year BETWEEN 1998 AND 2000
GROUP BY
    cc.cc_division,
    cc.cc_city,
    st.s_city,
    d_cs.d_year
HAVING SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100

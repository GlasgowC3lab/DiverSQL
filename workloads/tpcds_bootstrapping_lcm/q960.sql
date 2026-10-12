SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    st.s_state,
    (d_sold.d_year * 100 + d_sold.d_month_seq) AS year_month,
    CASE WHEN st.s_state IN ('CA','NY','TX') THEN 'Major' ELSE 'Other' END AS state_group,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS return_orders,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount,
    AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_delay_days,
    SUM(CASE WHEN st.s_closed_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS closed_store_cnt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(CASE WHEN d_closed.d_year = d_sold.d_year THEN 1 ELSE 0 END) AS closed_store_same_year_cnt
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN store_sales ss ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store st ON ss.ss_store_sk = st.s_store_sk
JOIN date_dim d_closed ON st.s_closed_date_sk = d_closed.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_sold.d_date_sk
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    st.s_state,
    CASE WHEN st.s_state IN ('CA','NY','TX') THEN 'Major' ELSE 'Other' END
HAVING SUM(cs.cs_net_paid) > 1000
ORDER BY total_catalog_net_paid DESC
LIMIT 100

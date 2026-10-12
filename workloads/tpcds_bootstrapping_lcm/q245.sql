SELECT
    dd_sold.d_year AS sold_year,
    dd_sold.d_month_seq AS sold_month,
    dd_ship.d_year AS ship_year,
    dd_ship.d_quarter_seq AS ship_quarter,
    dd_access.d_dow AS access_day_of_week,
    hd_bill.hd_vehicle_count AS bill_vehicle_cnt,
    hd_ship.hd_dep_count AS ship_dep_cnt,
    st.s_state AS store_state,
    st.s_division_name AS store_division,
    wp.wp_type AS web_page_type,
    sum(cs.cs_net_paid) AS total_net_paid,
    sum(cs.cs_ext_discount_amt) AS total_discount,
    avg(cs.cs_net_profit) AS avg_net_profit,
    count(*) AS order_count
FROM catalog_sales cs
JOIN date_dim dd_sold
    ON cs.cs_sold_date_sk = dd_sold.d_date_sk
JOIN date_dim dd_ship
    ON cs.cs_ship_date_sk = dd_ship.d_date_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN store st
    ON st.s_closed_date_sk = dd_sold.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = dd_ship.d_date_sk
JOIN date_dim dd_access
    ON wp.wp_access_date_sk = dd_access.d_date_sk
WHERE dd_sold.d_year BETWEEN 2020 AND 2022
GROUP BY
    dd_sold.d_year,
    dd_sold.d_month_seq,
    dd_ship.d_year,
    dd_ship.d_quarter_seq,
    dd_access.d_dow,
    hd_bill.hd_vehicle_count,
    hd_ship.hd_dep_count,
    st.s_state,
    st.s_division_name,
    wp.wp_type
ORDER BY total_net_paid DESC
LIMIT 100

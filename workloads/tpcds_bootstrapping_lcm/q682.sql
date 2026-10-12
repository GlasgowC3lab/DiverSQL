SELECT
    cp.cp_catalog_page_sk,
    cp.cp_department,
    cp.cp_catalog_page_number,
    cp.cp_type,
    d_start.d_year AS catalog_start_year,
    d_end.d_year   AS catalog_end_year,
    d_ship.d_month_seq AS ship_month_seq,
    d_ship.d_year      AS ship_year,
    d_common.d_year    AS sold_year,
    s.s_city,
    s.s_state,
    SUM(cs.cs_net_paid)      AS total_sales_net_paid,
    SUM(cs.cs_quantity)      AS total_quantity_sold,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt)    AS total_return_amount,
    SUM(wr.wr_net_loss)      AS total_return_net_loss
FROM catalog_page cp
JOIN catalog_sales cs
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_common
    ON cs.cs_sold_date_sk = d_common.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_common.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_common.d_date_sk
WHERE d_common.d_year = 2021
GROUP BY
    cp.cp_catalog_page_sk,
    cp.cp_department,
    cp.cp_catalog_page_number,
    cp.cp_type,
    d_start.d_year,
    d_end.d_year,
    d_ship.d_month_seq,
    d_ship.d_year,
    d_common.d_year,
    s.s_city,
    s.s_state
ORDER BY total_sales_net_paid DESC
LIMIT 100

SELECT
    cc_state,
    store_name,
    sold_year,
    ship_year,
    cc_closed_year,
    half_year,
    COUNT(DISTINCT order_number) AS orders,
    SUM(net_paid) AS total_sales,
    SUM(return_amt) AS total_returns,
    SUM(quantity) AS total_quantity,
    AVG(net_paid) AS avg_sales,
    COUNT(DISTINCT return_order) AS return_orders
FROM (
    SELECT
        cc.cc_state AS cc_state,
        s.s_store_name AS store_name,
        d_sold.d_year AS sold_year,
        d_ship.d_year AS ship_year,
        d_ccclosed.d_year AS cc_closed_year,
        d_sold.d_moy AS sold_month,
        CASE WHEN d_sold.d_moy <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
        cs.cs_order_number AS order_number,
        cs.cs_net_paid AS net_paid,
        cs.cs_quantity AS quantity,
        COALESCE(wr.wr_return_amt, 0.0) AS return_amt,
        wr.wr_order_number AS return_order
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN date_dim d_ccclosed
        ON cc.cc_closed_date_sk = d_ccclosed.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_sold.d_date_sk
) t
WHERE sold_year = 2020
GROUP BY
    cc_state,
    store_name,
    sold_year,
    ship_year,
    cc_closed_year,
    half_year
ORDER BY total_sales DESC
LIMIT 20

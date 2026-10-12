SELECT
    cc_name,
    s_store_name,
    sale_year,
    sale_month,
    ship_year,
    ship_month,
    cc_closed_year,
    shipping_delay_days,
    total_net_paid,
    total_net_profit,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        cc.cc_name AS cc_name,
        s.s_store_name AS s_store_name,
        d_sold.d_year AS sale_year,
        d_sold.d_month_seq AS sale_month,
        d_ship.d_year AS ship_year,
        d_ship.d_month_seq AS ship_month,
        d_cc_closed.d_year AS cc_closed_year,
        date_diff('day', d_sold.d_date, d_ship.d_date) AS shipping_delay_days,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    GROUP BY
        cc.cc_name,
        s.s_store_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_ship.d_year,
        d_ship.d_month_seq,
        d_cc_closed.d_year,
        date_diff('day', d_sold.d_date, d_ship.d_date)
) agg
ORDER BY total_net_profit DESC
LIMIT 100

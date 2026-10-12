WITH cs_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city,
        d_cc_closed.d_date_sk AS cc_closed_date_sk,
        d_cc_closed.d_date AS cc_closed_date,
        d_cc_open.d_date_sk AS cc_open_date_sk,
        d_cc_open.d_date AS cc_open_date,
        d_cc_closed.d_year AS cc_closed_year,
        d_cc_open.d_year AS cc_open_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_coupon_amt) AS avg_coupon_amt,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        MIN(d_sold.d_date) AS first_sold_date,
        MAX(d_ship.d_date) AS last_ship_date
    FROM call_center cc
    INNER JOIN catalog_sales cs
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    INNER JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    INNER JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    INNER JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_city,
        d_cc_closed.d_date_sk,
        d_cc_closed.d_date,
        d_cc_open.d_date_sk,
        d_cc_open.d_date,
        d_cc_closed.d_year,
        d_cc_open.d_year
)
SELECT
    agg.cc_name,
    agg.cc_city,
    s.s_store_name,
    s.s_city,
    agg.cc_closed_year,
    agg.cc_open_year,
    DATE_DIFF('day', agg.cc_open_date, agg.cc_closed_date) AS cc_lifespan_days,
    agg.total_net_paid,
    agg.total_net_profit,
    (agg.total_net_profit / NULLIF(agg.total_net_paid, 0)) * 100 AS profit_margin_percent,
    agg.avg_coupon_amt,
    agg.distinct_orders,
    agg.first_sold_date,
    agg.last_ship_date,
    s.s_floor_space,
    s.s_number_employees
FROM cs_agg agg
INNER JOIN store s
    ON s.s_closed_date_sk = agg.cc_closed_date_sk
WHERE agg.total_net_paid > 50000
ORDER BY agg.total_net_profit DESC
LIMIT 100

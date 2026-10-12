WITH aggregated AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        s.s_store_sk,
        s.s_store_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        MIN(dd_sold.d_date) AS first_sold_date,
        MAX(dd_ship.d_date) AS last_ship_date,
        dd_cc_open.d_date AS call_center_open_date,
        dd_cc_closed.d_date AS call_center_closed_date,
        dd_sold.d_year AS sold_year,
        dd_ship.d_year AS ship_year
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim dd_sold ON cs.cs_sold_date_sk = dd_sold.d_date_sk
    JOIN date_dim dd_ship ON cs.cs_ship_date_sk = dd_ship.d_date_sk
    JOIN store s ON s.s_closed_date_sk = dd_sold.d_date_sk
    JOIN date_dim dd_cc_closed ON cc.cc_closed_date_sk = dd_cc_closed.d_date_sk
    JOIN date_dim dd_cc_open ON cc.cc_open_date_sk = dd_cc_open.d_date_sk
    WHERE s.s_state = 'TX'
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        s.s_store_sk,
        s.s_store_name,
        dd_cc_open.d_date,
        dd_cc_closed.d_date,
        dd_sold.d_year,
        dd_ship.d_year
)
SELECT
    a.cc_call_center_sk,
    a.cc_name,
    a.s_store_sk,
    a.s_store_name,
    a.total_net_paid,
    a.total_net_profit,
    a.avg_discount,
    a.distinct_orders,
    a.first_sold_date,
    a.last_ship_date,
    a.call_center_open_date,
    a.call_center_closed_date,
    a.sold_year,
    a.ship_year,
    ROW_NUMBER() OVER (PARTITION BY a.cc_call_center_sk ORDER BY a.total_net_paid DESC) AS store_sales_rank
FROM aggregated a
WHERE a.sold_year BETWEEN 2000 AND 2002
ORDER BY a.total_net_paid DESC
LIMIT 100

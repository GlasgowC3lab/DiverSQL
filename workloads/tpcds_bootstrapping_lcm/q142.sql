WITH sales_summary AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        d_cc_open.d_year AS cc_open_year,
        d_cc_closed.d_year AS cc_closed_year,
        w.w_warehouse_id,
        w.w_city AS warehouse_city,
        s.s_store_id,
        s.s_city AS store_city,
        d_sold.d_year AS sold_year,
        d_ship.d_year AS ship_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
        AVG(cs.cs_quantity) AS avg_quantity,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_ext_tax) AS total_tax
    FROM catalog_sales cs
    INNER JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    INNER JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    INNER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    INNER JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    WHERE d_sold.d_year BETWEEN 2000 AND 2005
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        d_cc_open.d_year,
        d_cc_closed.d_year,
        w.w_warehouse_id,
        w.w_city,
        s.s_store_id,
        s.s_city,
        d_sold.d_year,
        d_ship.d_year
)
SELECT
    cc_call_center_id,
    cc_name,
    cc_open_year,
    cc_closed_year,
    w_warehouse_id,
    warehouse_city,
    s_store_id,
    store_city,
    sold_year,
    ship_year,
    total_net_paid,
    total_net_profit,
    distinct_items_sold,
    avg_quantity,
    total_discount,
    total_tax,
    ROW_NUMBER() OVER (PARTITION BY sold_year ORDER BY total_net_paid DESC) AS sales_rank_by_sold_year
FROM sales_summary
ORDER BY total_net_paid DESC
LIMIT 100

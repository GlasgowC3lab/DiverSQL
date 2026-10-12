WITH agg AS (
    SELECT
        cc.cc_name AS cc_name,
        cc.cc_state AS cc_state,
        d_sold.d_year AS d_year,
        d_sold.d_month_seq AS d_month_seq,
        i.i_category AS i_category,
        i.i_brand AS i_brand,
        s.s_store_name AS s_store_name,
        s.s_floor_space AS s_floor_space,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(i.i_current_price) AS avg_item_price,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        d_cc.d_date AS call_center_closed_date,
        d_sold.d_date AS sold_date
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN date_dim d_cc
        ON cc.cc_closed_date_sk = d_cc.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_cc.d_date_sk
    WHERE d_sold.d_year = 2002
      AND i.i_category = 'Electronics'
    GROUP BY
        cc.cc_name,
        cc.cc_state,
        d_sold.d_year,
        d_sold.d_month_seq,
        i.i_category,
        i.i_brand,
        s.s_store_name,
        s.s_floor_space,
        d_cc.d_date,
        d_sold.d_date
)
SELECT
    cc_name,
    cc_state,
    d_year,
    d_month_seq,
    i_category,
    i_brand,
    total_net_profit,
    total_quantity,
    avg_item_price,
    order_count,
    s_store_name,
    s_floor_space,
    call_center_closed_date,
    sold_date,
    ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY total_net_profit DESC
LIMIT 100

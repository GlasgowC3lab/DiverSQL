WITH agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        cc.cc_city AS call_center_city,
        sm.sm_type AS ship_mode,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_net_paid_inc_ship) AS total_sales,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT wp.wp_web_page_sk) AS pages_accessed
    FROM
        catalog_sales cs
    JOIN
        date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN
        call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN
        ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN
        item i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN
        web_page wp
        ON d_sold.d_date_sk = wp.wp_access_date_sk
    WHERE
        d_sold.d_year = 2022
        AND d_sold.d_quarter_name = 'Q4'
        AND i.i_category = 'Electronics'
        AND sm.sm_type = 'AIR'
        AND cc.cc_market_manager IN ('Julius Tran', 'Matthew Clifton')
        AND cc.cc_state = 'CA'
    GROUP BY
        cc.cc_name,
        cc.cc_city,
        sm.sm_type
    HAVING
        SUM(cs.cs_net_profit) > 100000
)
SELECT
    call_center_name,
    call_center_city,
    ship_mode,
    total_profit,
    total_sales,
    distinct_items_sold,
    avg_discount,
    pages_accessed,
    RANK() OVER (PARTITION BY ship_mode ORDER BY total_profit DESC) AS profit_rank
FROM
    agg
ORDER BY
    profit_rank,
    total_profit DESC
LIMIT 10

WITH aggregated AS (
    SELECT
        cc.cc_name AS call_center_name,
        cc.cc_manager AS call_center_manager,
        s.s_store_name AS store_name,
        d_sales.d_year AS year,
        d_sales.d_current_month AS month,
        d_store.d_date AS store_closed_date,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
        SUM(ss.ss_quantity) AS total_units_sold,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN inventory i
        ON i.inv_date_sk = d_sales.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_sales.d_date_sk
    JOIN date_dim d_store
        ON s.s_closed_date_sk = d_store.d_date_sk
    WHERE d_sales.d_year >= 2000
    GROUP BY
        cc.cc_name,
        cc.cc_manager,
        s.s_store_name,
        d_sales.d_year,
        d_sales.d_current_month,
        d_store.d_date
)
SELECT
    call_center_name,
    call_center_manager,
    store_name,
    year,
    month,
    total_sales,
    total_net_profit,
    total_inventory_on_hand,
    total_units_sold,
    avg_sales_price,
    ROW_NUMBER() OVER (PARTITION BY call_center_name, year, month ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 100

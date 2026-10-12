WITH filtered_sales AS (
    SELECT
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        i.i_category,
        s.s_state,
        d.d_year
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 1999
)
SELECT
    state,
    category,
    total_sales,
    total_profit,
    total_units,
    avg_discount,
    rank_in_state
FROM (
    SELECT
        s_state AS state,
        i_category AS category,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        SUM(ss_quantity) AS total_units,
        AVG(ss_ext_discount_amt) AS avg_discount,
        ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY SUM(ss_net_profit) DESC) AS rank_in_state
    FROM filtered_sales
    GROUP BY s_state, i_category
) t
WHERE rank_in_state <= 5
ORDER BY state, rank_in_state

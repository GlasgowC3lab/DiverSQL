WITH filtered_sales AS (
    SELECT
        s.ss_sold_time_sk,
        s.ss_store_sk,
        s.ss_item_sk,
        s.ss_customer_sk,
        s.ss_quantity,
        s.ss_sales_price,
        s.ss_ext_sales_price,
        s.ss_ext_discount_amt,
        s.ss_net_profit,
        s.ss_wholesale_cost,
        s.ss_list_price,
        s.ss_ext_wholesale_cost,
        s.ss_ext_tax,
        t.t_time,
        t.t_hour,
        t.t_minute,
        t.t_second,
        t.t_shift,
        t.t_meal_time
    FROM store_sales s
    JOIN time_dim t
      ON s.ss_sold_time_sk = t.t_time_sk
    WHERE s.ss_quantity > 1
      AND s.ss_sales_price > 10
      AND s.ss_ext_discount_amt < 100
      AND s.ss_net_profit > 0
      AND s.ss_wholesale_cost BETWEEN 20 AND 50
      AND t.t_hour BETWEEN 9 AND 17
      AND t.t_shift = 'second'
      AND t.t_second <> 12
),
small_dim AS (
    SELECT 'first' AS shift_label UNION ALL SELECT 'second' UNION ALL SELECT 'third'
),
multiplier AS (
    SELECT 1 AS mult UNION ALL SELECT 2 UNION ALL SELECT 3
)
SELECT
    fs.ss_store_sk,
    fs.ss_item_sk,
    fs.ss_customer_sk,
    fs.ss_quantity,
    fs.ss_sales_price,
    fs.ss_ext_sales_price,
    fs.t_shift,
    fs.t_hour,
    RANK() OVER (PARTITION BY fs.t_shift ORDER BY fs.ss_ext_sales_price DESC) AS rank_in_shift,
    SUM(fs.ss_ext_sales_price) OVER (PARTITION BY fs.t_shift ORDER BY fs.t_time ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_sum_3,
    CASE 
        WHEN fs.ss_net_profit >= 500 THEN 'high'
        WHEN fs.ss_net_profit >= 100 THEN 'medium'
        ELSE 'low'
    END AS profit_category,
    sd.shift_label,
    m.mult,
    -- correlated scalar subqueries for distinct aggregates per store
    (SELECT COUNT(DISTINCT s3.ss_customer_sk) FROM store_sales s3 WHERE s3.ss_store_sk = fs.ss_store_sk) AS store_distinct_customers,
    (SELECT COUNT(DISTINCT s3.ss_item_sk)     FROM store_sales s3 WHERE s3.ss_store_sk = fs.ss_store_sk) AS store_distinct_items,
    -- correlated scalar subquery for total profit per store
    (SELECT SUM(s2.ss_net_profit) FROM store_sales s2 WHERE s2.ss_store_sk = fs.ss_store_sk) AS store_total_profit
FROM filtered_sales fs
CROSS JOIN small_dim sd
CROSS JOIN multiplier m
WHERE sd.shift_label = fs.t_shift   -- keep rows where the generated dimension matches the actual shift
ORDER BY fs.t_shift, rank_in_shift, fs.ss_ext_sales_price DESC
LIMIT 100

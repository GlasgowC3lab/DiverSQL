WITH sales_with_time AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        td.t_time AS time_of_day,
        ss.ss_net_profit,
        i.i_category,
        i.i_item_sk
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
),
cumulative_sales AS (
    SELECT
        swt.ss_store_sk,
        swt.i_category,
        swt.time_of_day,
        swt.ss_net_profit,
        SUM(swt.ss_net_profit) OVER (PARTITION BY swt.ss_store_sk, swt.i_category
                                     ORDER BY swt.time_of_day
                                     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_category_profit,
        LAG(swt.ss_net_profit) OVER (PARTITION BY swt.ss_store_sk, swt.i_category ORDER BY swt.time_of_day) AS previous_profit
    FROM sales_with_time swt
    WHERE swt.ss_sold_date_sk = (SELECT MAX(ss2.ss_sold_date_sk) FROM store_sales ss2)
)
SELECT
    cs.ss_store_sk,
    cs.i_category,
    cs.time_of_day,
    cs.cumulative_category_profit,
    cs.previous_profit,
    CASE
        WHEN cs.previous_profit IS NULL THEN 0
        ELSE cs.ss_net_profit - cs.previous_profit
    END AS profit_change,
    RANK() OVER (PARTITION BY cs.ss_store_sk ORDER BY cs.cumulative_category_profit DESC) AS category_profit_rank
FROM cumulative_sales cs
ORDER BY cs.ss_store_sk, cs.i_category, cs.time_of_day

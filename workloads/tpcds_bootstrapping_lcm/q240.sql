WITH aggregated_sales AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        d_cc_open.d_date AS cc_open_date,
        d_cc_closed.d_date AS cc_closed_date,
        s.s_store_id,
        s.s_store_name,
        d_store_closed.d_date AS store_closed_date,
        d_sold.d_year,
        d_sold.d_month_seq,
        t.t_meal_time,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS transaction_cnt,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM store_sales ss
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    CROSS JOIN call_center cc
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    WHERE d_sold.d_date BETWEEN d_cc_open.d_date AND d_cc_closed.d_date
      AND d_sold.d_year = 2020
      AND t.t_meal_time = 'Dinner'
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        d_cc_open.d_date,
        d_cc_closed.d_date,
        s.s_store_id,
        s.s_store_name,
        d_store_closed.d_date,
        d_sold.d_year,
        d_sold.d_month_seq,
        t.t_meal_time
    HAVING SUM(ss.ss_ext_sales_price) > 10000
)
SELECT
    cc_call_center_id,
    cc_name,
    cc_open_date,
    cc_closed_date,
    s_store_id,
    s_store_name,
    store_closed_date,
    d_year,
    d_month_seq,
    t_meal_time,
    total_sales,
    total_profit,
    transaction_cnt,
    avg_sales_price,
    ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY total_sales DESC) AS store_rank
FROM aggregated_sales
ORDER BY cc_call_center_id, total_sales DESC
LIMIT 100

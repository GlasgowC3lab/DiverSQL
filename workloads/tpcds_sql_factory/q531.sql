WITH sales_with_time AS (
    SELECT
        ss.ss_ticket_number,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_sold_date_sk,
        td.t_hour,
        td.t_minute,
        td.t_shift,
        cd.cd_credit_rating,
        ss.ss_customer_sk,
        (td.t_hour * 60 + td.t_minute) AS minutes_of_day
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
),
sales_with_lag AS (
    SELECT
        *,
        LAG(minutes_of_day) OVER (PARTITION BY c_customer_id ORDER BY ss_sold_date_sk, minutes_of_day) AS prev_minutes_of_day,
        LAG(ss_sold_date_sk) OVER (PARTITION BY c_customer_id ORDER BY ss_sold_date_sk, minutes_of_day) AS prev_sold_date_sk
    FROM sales_with_time
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    ss_ticket_number,
    ss_store_sk,
    ss_item_sk,
    ss_quantity,
    ss_net_profit,
    t_shift,
    cd_credit_rating,
    minutes_of_day,
    prev_minutes_of_day,
    (minutes_of_day - COALESCE(prev_minutes_of_day, minutes_of_day)) AS minutes_since_last_sale,
    CASE
        WHEN (minutes_of_day - COALESCE(prev_minutes_of_day, minutes_of_day)) <= 30 THEN 'Frequent Buyer'
        ELSE 'Infrequent Buyer'
    END AS buyer_frequency_flag,
    SUM(ss_net_profit) OVER (PARTITION BY c_customer_id ORDER BY ss_sold_date_sk, minutes_of_day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_profit,
    ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY ss_sold_date_sk DESC, minutes_of_day DESC) AS recent_sale_rank,
    DENSE_RANK() OVER (PARTITION BY c_customer_id ORDER BY (minutes_of_day - COALESCE(prev_minutes_of_day, minutes_of_day))) AS interval_rank
FROM sales_with_lag
WHERE ss_quantity > 0
ORDER BY c_customer_id, ss_sold_date_sk, minutes_of_day

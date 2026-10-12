WITH filtered AS (
    SELECT
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_sales_price,
        ss.ss_coupon_amt,
        ss.ss_cdemo_sk,
        ss.ss_ext_list_price,
        ss.ss_ticket_number,
        td.t_meal_time,
        td.t_hour,
        td.t_minute
    FROM store_sales ss
    JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour IN (8, 13, 14)
      AND td.t_minute IN (5, 14, 16)
      AND td.t_meal_time IN ('breakfast', 'lunch')
      AND ss.ss_coupon_amt > 200
      AND ss.ss_cdemo_sk IN (1436274, 1091973)
      AND ss.ss_ext_list_price > 500
      AND ss.ss_quantity > 1
),
aggregated AS (
    SELECT
        t_meal_time,
        t_hour,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_ext_discount_amt) AS avg_discount,
        SUM(ss_quantity) AS total_quantity,
        MIN(ss_sales_price) AS min_sales_price,
        MAX(ss_sales_price) AS max_sales_price,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets
    FROM filtered
    GROUP BY t_meal_time, t_hour
)
SELECT
    t_meal_time,
    t_hour,
    total_sales,
    avg_discount,
    total_quantity,
    min_sales_price,
    max_sales_price,
    distinct_tickets,
    ROW_NUMBER() OVER (PARTITION BY t_meal_time ORDER BY total_sales DESC) AS meal_time_rank
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100

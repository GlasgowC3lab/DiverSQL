WITH sales_filtered AS (
    SELECT
        ws_sold_time_sk,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt
    FROM web_sales
    WHERE ws_list_price > 100.00                -- predicate 1
      AND ws_wholesale_cost < 90.00              -- predicate 2
      AND ws_quantity >= 1                      -- predicate 3
    GROUP BY ws_sold_time_sk
),
pm_sales AS (
    SELECT s.ws_sold_time_sk
    FROM sales_filtered s
    JOIN time_dim t ON s.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_am_pm = 'PM'
),
am_sales AS (
    SELECT s.ws_sold_time_sk
    FROM sales_filtered s
    JOIN time_dim t ON s.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_am_pm = 'AM'
),
common_times AS (
    SELECT ws_sold_time_sk FROM pm_sales
    INTERSECT
    SELECT ws_sold_time_sk FROM am_sales
),
joined AS (
    SELECT
        t.t_time_sk,
        t.t_time_id,
        t.t_hour,
        t.t_meal_time,
        sf.total_net_paid
    FROM time_dim t
    JOIN sales_filtered sf ON t.t_time_sk = sf.ws_sold_time_sk
    WHERE t.t_time_sk IN (SELECT ws_sold_time_sk FROM common_times)
      AND t.t_hour BETWEEN 12 AND 18           -- predicate 4
      AND t.t_am_pm = 'PM'                     -- predicate 5
)
SELECT
    t_time_id,
    t_hour,
    t_meal_time,
    total_net_paid,
    rn
FROM (
    SELECT
        t_time_id,
        t_hour,
        t_meal_time,
        total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY t_meal_time ORDER BY total_net_paid DESC) AS rn
    FROM joined
    WHERE total_net_paid > 1000.00              -- predicate 6
) ranked
WHERE rn <= 5                                    -- top‑k per group
ORDER BY t_meal_time, total_net_paid DESC
LIMIT 100

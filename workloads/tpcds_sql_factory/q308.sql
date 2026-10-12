SELECT
    t_hour,
    t_meal_time,
    total_sales,
    total_profit,
    order_cnt,
    avg_sales_per_order,
    DENSE_RANK() OVER (ORDER BY avg_sales_per_order DESC) AS sales_rank,
    discount_flag,
    profit_indicator
FROM (
    SELECT
        t.t_hour,
        t.t_meal_time,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        AVG(ws.ws_ext_sales_price) AS avg_sales_per_order,
        CASE
            WHEN MAX(p.p_discount_active) = 'Y' THEN 'DiscountActive'
            ELSE 'NoDiscount'
        END AS discount_flag,
        CASE
            WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable'
            ELSE 'Loss'
        END AS profit_indicator
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY t.t_hour, t.t_meal_time
) sub
ORDER BY sales_rank
LIMIT 10

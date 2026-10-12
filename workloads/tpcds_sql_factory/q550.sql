WITH sales_by_day AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        d.d_date,
        SUM(ws.ws_net_profit) AS daily_profit,
        COUNT(*) AS daily_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_bill_customer_sk, d.d_date
),
customer_agg AS (
    SELECT
        customer_sk,
        SUM(daily_profit) AS total_profit,
        COUNT(DISTINCT d_date) AS active_days,
        SUM(daily_orders) AS total_orders,
        AVG(daily_profit) AS avg_daily_profit,
        SUM(CASE WHEN EXTRACT(DOW FROM d_date) IN (6,7) THEN daily_orders ELSE 0 END) AS weekend_orders
    FROM sales_by_day
    GROUP BY customer_sk
),
customer_rank AS (
    SELECT
        ca.*, 
        RANK() OVER (ORDER BY ca.total_profit DESC) AS profit_rank,
        CUME_DIST() OVER (ORDER BY ca.total_profit DESC) AS cum_dist
    FROM customer_agg ca
)
SELECT
    cr.customer_sk,
    cr.total_profit,
    cr.active_days,
    cr.total_orders,
    cr.avg_daily_profit,
    cr.weekend_orders,
    CASE WHEN cr.total_orders > 0 THEN cr.weekend_orders * 1.0 / cr.total_orders ELSE 0 END AS weekend_order_ratio,
    cr.profit_rank,
    CASE 
        WHEN cr.cum_dist <= 0.10 THEN 'Top 10%'
        WHEN cr.cum_dist <= 0.40 THEN 'Top 40%'
        ELSE 'Other'
    END AS segment
FROM customer_rank cr
WHERE cr.profit_rank <= 200
ORDER BY cr.profit_rank

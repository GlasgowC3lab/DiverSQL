WITH customer_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        MIN(d.d_date) AS first_purchase_date,
        MAX(d.d_date) AS last_purchase_date,
        AVG(ws.ws_ext_sales_price) AS avg_order_value,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS promo_order_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY ws.ws_bill_customer_sk
),
customer_hour AS (
    SELECT
        customer_sk,
        t_hour,
        hour_cnt,
        ROW_NUMBER() OVER (PARTITION BY customer_sk ORDER BY hour_cnt DESC) AS hr_rank
    FROM (
        SELECT
            ws.ws_bill_customer_sk AS customer_sk,
            t.t_hour,
            COUNT(*) AS hour_cnt
        FROM web_sales ws
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        GROUP BY ws.ws_bill_customer_sk, t.t_hour
    ) agg
),
customer_rank AS (
    SELECT
        ca.*, 
        PERCENT_RANK() OVER (ORDER BY ca.total_profit DESC) AS pct_rank
    FROM customer_agg ca
)
SELECT
    cr.customer_sk,
    cr.total_profit,
    cr.order_cnt,
    cr.first_purchase_date,
    cr.last_purchase_date,
    cr.avg_order_value,
    cr.promo_order_cnt,
    CASE WHEN cr.order_cnt > 0 THEN cr.promo_order_cnt * 1.0 / cr.order_cnt ELSE 0 END AS promo_ratio,
    RANK() OVER (ORDER BY cr.total_profit DESC) AS profit_rank,
    CASE 
        WHEN cr.pct_rank <= 0.10 THEN 'Platinum'
        WHEN cr.pct_rank <= 0.30 THEN 'Gold'
        ELSE 'Silver'
    END AS tier,
    ch.t_hour AS favorite_hour,
    ch.hour_cnt AS favorite_hour_orders
FROM customer_rank cr
LEFT JOIN (
    SELECT customer_sk, t_hour, hour_cnt
    FROM customer_hour
    WHERE hr_rank = 1
) ch ON cr.customer_sk = ch.customer_sk
ORDER BY profit_rank
LIMIT 100

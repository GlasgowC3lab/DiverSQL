WITH base AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_order_number,
        d.d_date,
        p.p_discount_active,
        t.t_hour
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE d.d_month_seq BETWEEN 202201 AND 202212
),
customer_agg AS (
    SELECT
        customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_cnt,
        MIN(d_date) AS first_purchase_date,
        MAX(d_date) AS last_purchase_date,
        AVG(ws_ext_sales_price) AS avg_order_value,
        SUM(CASE WHEN p_discount_active = 'Y' THEN 1 ELSE 0 END) AS promo_order_cnt
    FROM base
    GROUP BY customer_sk
),
favorite_hour AS (
    SELECT
        customer_sk,
        t_hour,
        COUNT(*) AS hour_cnt,
        ROW_NUMBER() OVER (PARTITION BY customer_sk ORDER BY COUNT(*) DESC) AS rn
    FROM base
    GROUP BY customer_sk, t_hour
),
ranked AS (
    SELECT
        ca.*, 
        ROW_NUMBER() OVER (ORDER BY ca.total_profit DESC) AS profit_rank,
        PERCENT_RANK() OVER (ORDER BY ca.total_profit DESC) AS pct_rank
    FROM customer_agg ca
)
SELECT
    r.customer_sk,
    r.total_profit,
    r.order_cnt,
    r.first_purchase_date,
    r.last_purchase_date,
    r.avg_order_value,
    r.promo_order_cnt,
    CASE WHEN r.order_cnt > 0 THEN r.promo_order_cnt * 1.0 / r.order_cnt ELSE 0 END AS promo_ratio,
    r.profit_rank,
    CASE 
        WHEN r.pct_rank <= 0.05 THEN 'Elite'
        WHEN r.pct_rank <= 0.25 THEN 'Preferred'
        ELSE 'Standard'
    END AS tier,
    fh.t_hour AS favorite_hour,
    fh.hour_cnt AS favorite_hour_orders
FROM ranked r
LEFT JOIN (
    SELECT customer_sk, t_hour, hour_cnt
    FROM favorite_hour
    WHERE rn = 1
) fh ON r.customer_sk = fh.customer_sk
ORDER BY r.profit_rank
LIMIT 100

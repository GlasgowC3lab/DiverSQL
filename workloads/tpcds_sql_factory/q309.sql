WITH promo_sales AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        start_d.d_date AS start_date,
        end_d.d_date AS end_date,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_cnt,
        DATE_DIFF('day', start_d.d_date, end_d.d_date) + 1 AS promo_days,
        AVG(t.t_hour) AS avg_sale_hour
    FROM promotion p
    JOIN date_dim start_d ON p.p_start_date_sk = start_d.d_date_sk
    JOIN date_dim end_d ON p.p_end_date_sk = end_d.d_date_sk
    LEFT JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
        AND ws.ws_sold_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    LEFT JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    GROUP BY p.p_promo_id, p.p_promo_name, p.p_cost, start_d.d_date, end_d.d_date
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    p.start_date,
    p.end_date,
    p.total_sales,
    p.total_profit,
    p.p_cost,
    p.order_cnt,
    p.promo_days,
    p.avg_sale_hour,
    CASE 
        WHEN p.p_cost > 0 THEN p.total_profit / p.p_cost
        ELSE NULL
    END AS roi,
    CASE 
        WHEN p.p_cost > 0 AND p.total_profit / p.p_cost > 2 THEN 'High'
        WHEN p.p_cost > 0 AND p.total_profit / p.p_cost BETWEEN 1 AND 2 THEN 'Medium'
        ELSE 'Low'
    END AS roi_category,
    RANK() OVER (ORDER BY CASE 
        WHEN p.p_cost > 0 THEN p.total_profit / p.p_cost 
        ELSE NULL 
    END DESC) AS roi_rank
FROM promo_sales p
WHERE p.p_cost IS NOT NULL
ORDER BY roi_rank
LIMIT 20

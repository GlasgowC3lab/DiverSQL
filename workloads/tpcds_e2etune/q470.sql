WITH agg AS (
    SELECT
        w.w_warehouse_name,
        w.w_city,
        p.p_promo_name,
        t.t_shift,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        COUNT(*) AS transaction_count
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 8 AND 20
      AND cs.cs_sold_date_sk BETWEEN 2450820 AND 2450830
    GROUP BY w.w_warehouse_name, w.w_city, p.p_promo_name, t.t_shift
)
SELECT
    agg.w_warehouse_name,
    agg.w_city,
    agg.p_promo_name,
    agg.t_shift,
    agg.total_net_profit,
    agg.avg_sales_price,
    agg.transaction_count,
    RANK() OVER (ORDER BY agg.total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY agg.total_net_profit DESC
LIMIT 10

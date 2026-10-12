WITH hourly_sales_metrics AS (
    SELECT
        t.t_hour,
        t.t_shift,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
        SUM(CASE WHEN cs.cs_promo_sk IS NOT NULL THEN cs.cs_net_paid_inc_tax ELSE 0 END) AS promo_net_paid
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cs.cs_net_paid_inc_tax > 5000
      AND cs.cs_ext_discount_amt > 0
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY t.t_hour, t.t_shift
    HAVING SUM(cs.cs_net_profit) > 0
       AND COUNT(*) > 10
)
SELECT
    t_hour,
    t_shift,
    total_profit,
    avg_discount,
    total_quantity,
    sales_cnt,
    total_net_paid,
    promo_net_paid,
    total_profit / total_net_paid AS profit_margin,
    promo_net_paid / total_net_paid AS promo_contribution,
    RANK() OVER (PARTITION BY t_shift ORDER BY total_profit DESC) AS profit_rank_within_shift
FROM hourly_sales_metrics
ORDER BY total_profit DESC
LIMIT 50

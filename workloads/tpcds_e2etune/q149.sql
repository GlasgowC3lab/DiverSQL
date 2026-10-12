WITH agg AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        sm.sm_type,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_ship_cost) AS avg_ext_ship_cost,
        COUNT(*) AS orders_count
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450820 AND 2450826
      AND cs.cs_ext_ship_cost > 200.00
      AND cs.cs_ship_customer_sk IN (3662153, 6114601, 4367572)
    GROUP BY sm.sm_ship_mode_id, sm.sm_carrier, sm.sm_type
    HAVING SUM(cs.cs_net_profit) > 0
)
SELECT
    sm_ship_mode_id,
    sm_carrier,
    sm_type,
    total_net_profit,
    avg_ext_ship_cost,
    orders_count,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY total_net_profit DESC
LIMIT 10

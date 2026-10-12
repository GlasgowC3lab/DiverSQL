WITH sales_agg AS (
    SELECT
        td.t_hour,
        td.t_shift,
        hd.hd_vehicle_count,
        hd.hd_buy_potential,
        COUNT(*) AS sales_cnt,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_net_profit) AS avg_net_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_list_price > 150
      AND cs.cs_promo_sk IN (1096, 1170, 284)
      AND hd.hd_vehicle_count >= 2
      AND hd.hd_buy_potential = 'HIGH'
    GROUP BY td.t_hour, td.t_shift, hd.hd_vehicle_count, hd.hd_buy_potential
    HAVING COUNT(*) >= 10
)
SELECT
    t_hour,
    t_shift,
    hd_vehicle_count,
    hd_buy_potential,
    sales_cnt,
    total_net_profit,
    avg_net_profit,
    total_discount,
    RANK() OVER (ORDER BY avg_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY profit_rank
LIMIT 5

WITH sales_agg AS (
    SELECT
        cc.cc_state AS state,
        cc.cc_city AS city,
        sm.sm_ship_mode_id AS ship_mode_id,
        sm.sm_type AS ship_type,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        AVG(cs.cs_ext_ship_cost) AS avg_ship_cost,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_rec_end_date <= DATE '2001-12-31'
      AND cc.cc_state IN ('TN', 'GA')
      AND sm.sm_type = 'AIR'
    GROUP BY cc.cc_state, cc.cc_city, sm.sm_ship_mode_id, sm.sm_type
)
SELECT
    state,
    city,
    ship_mode_id,
    ship_type,
    total_net_profit,
    total_discount,
    avg_ship_cost,
    sales_cnt,
    RANK() OVER (PARTITION BY ship_type ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
WHERE total_net_profit > 10000
ORDER BY profit_rank, total_net_profit DESC
LIMIT 20

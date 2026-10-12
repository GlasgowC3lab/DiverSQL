WITH sampled_sales AS (
   SELECT *
   FROM catalog_sales
   TABLESAMPLE BERNOULLI (10)
),
joined AS (
   SELECT
      cs.cs_order_number,
      cs.cs_net_profit,
      cs.cs_quantity,
      cc.cc_call_center_id,
      cc.cc_name,
      cc.cc_state,
      sm.sm_ship_mode_id,
      sm.sm_type,
      sm.sm_carrier,
      cd.cd_education_status,
      cd.cd_credit_rating,
      hd.hd_income_band_sk
   FROM sampled_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE cc.cc_state = 'CA'
     AND sm.sm_type = 'EXPRESS'
     AND cd.cd_credit_rating = 'High Risk'
),
agg_by_center AS (
   SELECT
      cc_call_center_id,
      sm_ship_mode_id,
      SUM(cs_net_profit) AS total_profit,
      AVG(cs_quantity) AS avg_qty,
      COUNT(*) AS txn_cnt
   FROM joined
   GROUP BY cc_call_center_id, sm_ship_mode_id
   HAVING SUM(cs_net_profit) > 10000
),
agg_by_ship AS (
   SELECT
      sm_ship_mode_id,
      SUM(cs_net_profit) AS ship_profit
   FROM joined
   GROUP BY sm_ship_mode_id
   HAVING SUM(cs_net_profit) > 20000
),
intersect_ship_modes AS (
   SELECT sm_ship_mode_id FROM agg_by_center
   INTERSECT
   SELECT sm_ship_mode_id FROM agg_by_ship
),
small_dim AS (
   SELECT sm_ship_mode_id
   FROM ship_mode
   WHERE sm_type = 'EXPRESS'
   LIMIT 5
),
computed_set AS (
   SELECT column1 FROM (VALUES (1), (2), (3)) AS t(column1)
),
crossed AS (
   SELECT sd.sm_ship_mode_id, cs.column1
   FROM small_dim sd
   CROSS JOIN computed_set cs
)
SELECT
   i.sm_ship_mode_id,
   c.total_profit,
   c.avg_qty,
   c.txn_cnt,
   cr.column1 AS seq_number
FROM intersect_ship_modes i
JOIN agg_by_center c ON i.sm_ship_mode_id = c.sm_ship_mode_id
JOIN crossed cr ON cr.sm_ship_mode_id = i.sm_ship_mode_id
ORDER BY c.total_profit DESC
LIMIT 100

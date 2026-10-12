WITH demo_store_agg AS (
   SELECT
       hd.hd_income_band_sk,
       hd.hd_vehicle_count,
       hd.hd_dep_count,
       hd.hd_buy_potential,
       s.s_state,
       COUNT(*) AS num_returns,
       SUM(sr.sr_net_loss) AS total_net_loss,
       SUM(sr.sr_return_quantity) AS total_return_quantity,
       AVG(sr.sr_net_loss) AS avg_net_loss_per_return,
       CASE 
           WHEN SUM(sr.sr_net_loss) > 30000 THEN 'High'
           WHEN SUM(sr.sr_net_loss) BETWEEN 10000 AND 30000 THEN 'Medium'
           ELSE 'Low'
       END AS loss_level
   FROM store_returns sr
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   GROUP BY hd.hd_income_band_sk, hd.hd_vehicle_count, hd.hd_dep_count, hd.hd_buy_potential, s.s_state
)
SELECT
   hd_income_band_sk,
   hd_vehicle_count,
   hd_dep_count,
   hd_buy_potential,
   s_state,
   num_returns,
   total_net_loss,
   total_return_quantity,
   avg_net_loss_per_return,
   loss_level,
   NTILE(5) OVER (PARTITION BY s_state ORDER BY total_net_loss DESC) AS net_loss_quintile_state,
   PERCENT_RANK() OVER (PARTITION BY s_state ORDER BY total_net_loss DESC) AS net_loss_percentile_state,
   CASE WHEN loss_level = 'High' AND total_return_quantity > 100 THEN 'Critical' ELSE 'Normal' END AS risk_flag
FROM demo_store_agg
ORDER BY s_state, net_loss_quintile_state, hd_income_band_sk
LIMIT 50

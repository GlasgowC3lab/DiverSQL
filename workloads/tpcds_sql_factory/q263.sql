WITH store_agg AS (
   SELECT
       s.s_store_sk,
       s.s_store_id,
       s.s_store_name,
       s.s_city,
       s.s_state,
       SUM(sr.sr_net_loss) AS total_net_loss,
       SUM(sr.sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
       SUM(sr.sr_store_credit) AS total_store_credit,
       SUM(sr.sr_return_quantity) AS total_return_quantity,
       SUM(CASE WHEN hd.hd_buy_potential = 'HIGH' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS pct_high_buy_potential,
       CASE WHEN SUM(sr.sr_net_loss) > 50000 THEN 'High Loss' ELSE 'Moderate/Low Loss' END AS loss_category
   FROM store_returns sr
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name, s.s_city, s.s_state
)
SELECT
   s_store_id,
   s_store_name,
   s_city,
   s_state,
   total_net_loss,
   total_return_amt_inc_tax,
   total_store_credit,
   total_return_quantity,
   pct_high_buy_potential,
   loss_category,
   RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank,
   ROUND(total_net_loss / NULLIF(total_return_quantity, 0), 2) AS avg_loss_per_item
FROM store_agg
ORDER BY net_loss_rank
LIMIT 20

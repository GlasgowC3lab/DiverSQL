WITH reason_agg AS (
   SELECT
       r.r_reason_sk,
       r.r_reason_desc,
       CASE 
           WHEN LOWER(r.r_reason_desc) LIKE '%customer%' THEN 'Customer'
           WHEN LOWER(r.r_reason_desc) LIKE '%system%' THEN 'System'
           ELSE 'Other'
       END AS reason_category,
       s.s_state,
       COUNT(*) AS total_returns,
       SUM(sr.sr_net_loss) AS total_net_loss,
       AVG(sr.sr_return_amt) AS avg_return_amt,
       SUM(sr.sr_net_loss) * 1.0 / COUNT(*) AS avg_loss_per_return
   FROM store_returns sr
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   GROUP BY r.r_reason_sk, r.r_reason_desc, s.s_state
)
SELECT
   r_reason_sk,
   r_reason_desc,
   reason_category,
   s_state,
   total_returns,
   total_net_loss,
   avg_return_amt,
   avg_loss_per_return,
   DENSE_RANK() OVER (ORDER BY avg_loss_per_return DESC) AS loss_per_return_rank,
   SUM(total_returns) OVER (PARTITION BY s_state) AS state_total_returns,
   SUM(total_net_loss) OVER (PARTITION BY s_state) AS state_total_loss,
   PERCENT_RANK() OVER (ORDER BY avg_loss_per_return DESC) AS loss_per_return_percentile
FROM reason_agg
ORDER BY loss_per_return_rank
LIMIT 20

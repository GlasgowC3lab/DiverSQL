WITH latest_return AS (
   SELECT
       sr.sr_returned_date_sk,
       sr.sr_return_time_sk,
       sr.sr_store_sk,
       s.s_store_id,
       s.s_store_name,
       sr.sr_return_amt_inc_tax,
       sr.sr_net_loss,
       r.r_reason_desc,
       hd.hd_buy_potential,
       SUM(sr.sr_net_loss) OVER (PARTITION BY sr.sr_store_sk ORDER BY sr.sr_returned_date_sk, sr.sr_return_time_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss,
       ROW_NUMBER() OVER (PARTITION BY sr.sr_store_sk ORDER BY sr.sr_returned_date_sk DESC, sr.sr_return_time_sk DESC) AS rn,
       CASE WHEN sr.sr_return_amt_inc_tax > 500 THEN 'Large Return' ELSE 'Small Return' END AS return_size_category
   FROM store_returns sr
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   LEFT JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
)
SELECT
   s_store_id,
   s_store_name,
   sr_returned_date_sk,
   sr_return_time_sk,
   sr_return_amt_inc_tax,
   sr_net_loss,
   cumulative_net_loss,
   return_size_category,
   r_reason_desc,
   hd_buy_potential
FROM latest_return
WHERE rn = 1
ORDER BY cumulative_net_loss DESC
LIMIT 25

SELECT
  p.p_promo_id,
  p.p_promo_name,
  p.p_channel_radio,
  p.p_channel_email,
  p.p_channel_tv,
  SUM(sr.sr_return_amt) AS total_return_amt,
  AVG(sr.sr_return_quantity) AS avg_return_qty,
  SUM(p.p_cost) AS total_promo_cost,
  SUM(sr.sr_net_loss) AS total_net_loss,
  COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
  SUM(sr.sr_return_amt) / NULLIF(SUM(p.p_cost), 0) AS roi,
  RANK() OVER (ORDER BY SUM(sr.sr_return_amt) / NULLIF(SUM(p.p_cost), 0) DESC) AS promo_rank
FROM promotion p
JOIN store_returns sr
  ON p.p_item_sk = sr.sr_item_sk
WHERE p.p_purpose = 'Unknown'
  AND p.p_response_target = 1
  AND sr.sr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
GROUP BY
  p.p_promo_id,
  p.p_promo_name,
  p.p_channel_radio,
  p.p_channel_email,
  p.p_channel_tv
HAVING SUM(sr.sr_return_amt) > 1000
ORDER BY roi DESC
LIMIT 50

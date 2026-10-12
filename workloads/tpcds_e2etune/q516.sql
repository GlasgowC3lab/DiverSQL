SELECT
  cp.cp_department,
  p.p_promo_name,
  cd.cd_gender,
  dr.d_year,
  dr.d_moy AS month,
  COUNT(*) AS return_count,
  SUM(sr.sr_net_loss) AS total_net_loss,
  AVG(sr.sr_return_amt) AS avg_return_amount,
  SUM(CASE WHEN p.p_channel_tv = 'Y' THEN 1 ELSE 0 END) AS tv_promo_returns,
  SUM(CASE WHEN p.p_channel_email = 'Y' THEN 1 ELSE 0 END) AS email_promo_returns
FROM store_returns sr
JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
JOIN promotion p ON sr.sr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
JOIN date_dim dp_start ON p.p_start_date_sk = dp_start.d_date_sk
JOIN date_dim dp_end ON p.p_end_date_sk = dp_end.d_date_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = dp_start.d_date_sk
WHERE dr.d_year = 2002
  AND cd.cd_credit_rating = 'A'
  AND p.p_discount_active = 'Y'
  AND cp.cp_type = 'monthly'
GROUP BY cp.cp_department, p.p_promo_name, cd.cd_gender, dr.d_year, dr.d_moy
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100

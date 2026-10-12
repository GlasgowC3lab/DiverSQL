SELECT p.p_promo_id,
       p.p_cost,
       d.d_date
FROM promotion p
JOIN date_dim d
  ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_current_year = 'Y'
  AND p.p_channel_catalog = 'N'

SELECT
  ca.ca_state AS state,
  i.i_category AS category,
  COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
  SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
  SUM(p.p_cost) AS total_promo_cost,
  AVG(i.i_current_price) AS avg_item_price,
  ROUND(SUM(sr.sr_return_amt_inc_tax) / NULLIF(SUM(p.p_cost), 0), 2) AS return_to_promo_ratio
FROM store_returns sr
JOIN date_dim d_ret
  ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc
  ON cc.cc_open_date_sk = d_ret.d_date_sk OR cc.cc_closed_date_sk = d_ret.d_date_sk
JOIN item i
  ON sr.sr_item_sk = i.i_item_sk
JOIN promotion p
  ON p.p_item_sk = i.i_item_sk
JOIN date_dim d_start
  ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
  ON p.p_end_date_sk = d_end.d_date_sk
JOIN customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
WHERE
  d_ret.d_year = 2020
  AND d_ret.d_date_sk BETWEEN d_start.d_date_sk AND d_end.d_date_sk
  AND i.i_category IS NOT NULL
  AND p.p_cost > 0
  AND ca.ca_state IN ('CA', 'NY', 'TX')
  AND cc.cc_company = 2
  AND cc.cc_class = 'large'
  AND cc.cc_market_manager = 'Julius Tran'
  AND cc.cc_open_date_sk IN (2450952, 2450806)
GROUP BY
  ca.ca_state,
  i.i_category
HAVING
  SUM(sr.sr_return_amt_inc_tax) > 5000
ORDER BY
  total_return_amount DESC
LIMIT 50

WITH store_returns AS (
  SELECT 
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_ret.d_year AS return_year,
    d_ret.d_current_quarter AS return_quarter,
    d_store.d_year AS store_closed_year,
    d_store.d_current_quarter AS store_closed_quarter,
    hd_ret.hd_buy_potential AS returning_buy_potential,
    hd_ret.hd_income_band_sk AS returning_income_band,
    hd_ref.hd_buy_potential AS refunded_buy_potential,
    hd_ref.hd_income_band_sk AS refunded_income_band,
    ca_ret.ca_city AS returning_address_city,
    ca_ret.ca_state AS returning_address_state,
    ca_ref.ca_city AS refunded_address_city,
    ca_ref.ca_state AS refunded_address_state,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS num_returns,
    AVG(wr.wr_return_quantity) AS avg_quantity
  FROM web_returns wr
  JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
  JOIN household_demographics hd_ret ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
  JOIN customer_address ca_ret ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
  JOIN household_demographics hd_ref ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
  JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
  JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
  GROUP BY 
    s.s_store_id, s.s_store_name, s.s_city, s.s_state,
    d_ret.d_year, d_ret.d_current_quarter,
    d_store.d_year, d_store.d_current_quarter,
    hd_ret.hd_buy_potential, hd_ret.hd_income_band_sk,
    hd_ref.hd_buy_potential, hd_ref.hd_income_band_sk,
    ca_ret.ca_city, ca_ret.ca_state,
    ca_ref.ca_city, ca_ref.ca_state
)
SELECT 
  s_store_id,
  s_store_name,
  s_city,
  s_state,
  return_year,
  return_quarter,
  store_closed_year,
  store_closed_quarter,
  returning_buy_potential,
  returning_income_band,
  refunded_buy_potential,
  refunded_income_band,
  returning_address_city,
  returning_address_state,
  refunded_address_city,
  refunded_address_state,
  total_return_amount,
  total_net_loss,
  num_returns,
  avg_quantity,
  ROW_NUMBER() OVER (PARTITION BY return_year, return_quarter ORDER BY total_net_loss DESC) AS loss_rank_in_quarter
FROM store_returns
ORDER BY total_net_loss DESC, loss_rank_in_quarter
LIMIT 200

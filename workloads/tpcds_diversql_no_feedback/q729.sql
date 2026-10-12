WITH joined_data AS (
  SELECT
    ca.ca_state,
    ca.ca_city,
    ca.ca_street_type,
    ca.ca_gmt_offset,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    sr.sr_return_tax,
    sr.sr_return_ship_cost,
    sr.sr_net_loss,
    sr.sr_return_quantity,
    sr.sr_ticket_number
  FROM store_returns sr
  JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE ca.ca_street_type IN ('Ave', 'Blvd', 'Rd', 'Ln')
    AND ca.ca_gmt_offset BETWEEN -7.00 AND -5.00
    AND ib.ib_lower_bound >= 120000
    AND sr.sr_return_tax > 2.00
    AND sr.sr_return_ship_cost < 500.00
),
cube_agg AS (
  SELECT
    ca_state,
    ca_city,
    ca_street_type,
    ib_income_band_sk,
    hd_buy_potential,
    SUM(sr_net_loss) AS total_net_loss,
    SUM(sr_return_quantity) AS total_qty,
    COUNT(DISTINCT sr_ticket_number) AS distinct_tickets
  FROM joined_data
  GROUP BY CUBE (ca_state, ca_city, ca_street_type, ib_income_band_sk, hd_buy_potential)
)
SELECT
  ca_state,
  ca_city,
  ca_street_type,
  ib_income_band_sk,
  hd_buy_potential,
  total_net_loss,
  total_qty,
  distinct_tickets,
  total_net_loss / NULLIF(total_qty, 0) AS avg_loss_per_qty
FROM cube_agg
WHERE total_net_loss > 1000
  AND total_qty >= 10
  AND distinct_tickets >= 5
ORDER BY total_net_loss DESC
LIMIT 100

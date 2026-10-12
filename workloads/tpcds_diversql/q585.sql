WITH
  ws_enriched AS (
    SELECT
      ws.ws_order_number,
      d.d_year,
      i.i_item_id,
      i.i_brand,
      i.i_category,
      ca.ca_state,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ws.ws_ext_sales_price DESC) AS rn_sales_year,
      l.disc_ratio
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN LATERAL (
      SELECT CASE WHEN ws.ws_ext_sales_price = 0 THEN 0
                  ELSE ws.ws_ext_discount_amt / ws.ws_ext_sales_price END AS disc_ratio
    ) l ON true
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_brand = 'Brand#12'
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND ws.ws_quantity > 0
      AND ws.ws_net_profit > 0
  ),

  sr_enriched AS (
    SELECT
      sr.sr_ticket_number,
      d.d_year,
      i.i_item_id,
      i.i_brand,
      i.i_category,
      ca.ca_state,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_net_loss,
      RANK() OVER (PARTITION BY d.d_year ORDER BY sr.sr_return_amt DESC) AS rnk_return_year,
      l.loss_ratio
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN LATERAL (
      SELECT CASE WHEN sr.sr_return_amt = 0 THEN 0
                  ELSE sr.sr_net_loss / sr.sr_return_amt END AS loss_ratio
    ) l ON true
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND s.s_state = 'CA'
      AND i.i_category = 'Category#7'
      AND ca.ca_state = 'CA'
      AND sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 0
  ),

  cc_enriched AS (
    SELECT
      cc.cc_call_center_id,
      d.d_year,
      cc.cc_name,
      cc.cc_employees,
      cc.cc_gmt_offset
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cc.cc_employees > 0
      AND cc.cc_gmt_offset BETWEEN -5 AND 5
  ),

  common_items AS (
    SELECT i_item_id, d_year FROM sr_enriched
    INTERSECT
    SELECT i_item_id, d_year FROM ws_enriched
  )
SELECT
  ws.ws_order_number,
  ws.d_year,
  ws.i_item_id,
  ws.i_brand,
  ws.i_category,
  ws.ca_state AS bill_state,
  ws.ws_quantity,
  ws.ws_ext_sales_price,
  ws.disc_ratio,
  ws.rn_sales_year,
  cc.cc_call_center_id,
  cc.cc_name AS call_center_name,
  cc.cc_employees,
  sr.rnk_return_year,
  sr.sr_return_amt,
  sr.loss_ratio
FROM ws_enriched ws
JOIN cc_enriched cc ON ws.d_year = cc.d_year
JOIN common_items ci ON ws.i_item_id = ci.i_item_id AND ws.d_year = ci.d_year
LEFT JOIN sr_enriched sr ON ws.i_item_id = sr.i_item_id AND ws.d_year = sr.d_year
WHERE ws.rn_sales_year <= 5
ORDER BY ws.d_year DESC, ws.ws_ext_sales_price DESC
LIMIT 100

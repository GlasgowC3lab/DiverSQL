WITH category_state_loss AS (
  SELECT
    ca.ca_state AS state,
    i.i_category AS category,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_amt) AS avg_return_amt,
    SUM(sr.sr_return_quantity) AS total_qty,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(sr.sr_net_loss) DESC) AS loss_rank
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  WHERE i.i_current_price > 100
    AND ca.ca_state IN ('AZ', 'NM', 'PA', 'CO', 'MO')
    AND sr.sr_returned_date_sk >= 2450000
  GROUP BY ca.ca_state, i.i_category
)
SELECT
  state,
  category,
  return_cnt,
  total_net_loss,
  avg_return_amt,
  total_qty,
  loss_rank
FROM category_state_loss
WHERE loss_rank <= 5
ORDER BY state, loss_rank

WITH promo_cost AS (
  SELECT p_item_sk, SUM(p_cost) AS total_promo_cost
  FROM promotion
  GROUP BY p_item_sk
),
returns AS (
  SELECT
    cr.cr_item_sk AS item_sk,
    ca.ca_state AS state,
    'catalog' AS channel,
    cr.cr_return_quantity AS qty,
    cr.cr_return_amt_inc_tax AS amt_inc_tax,
    cr.cr_net_loss AS net_loss,
    cr.cr_returned_date_sk AS date_sk
  FROM catalog_returns cr
  JOIN customer_address ca
    ON cr.cr_returning_addr_sk = ca.ca_address_sk
  UNION ALL
  SELECT
    sr.sr_item_sk AS item_sk,
    ca.ca_state AS state,
    'store' AS channel,
    sr.sr_return_quantity AS qty,
    sr.sr_return_amt_inc_tax AS amt_inc_tax,
    sr.sr_net_loss AS net_loss,
    sr.sr_returned_date_sk AS date_sk
  FROM store_returns sr
  JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
  UNION ALL
  SELECT
    wr.wr_item_sk AS item_sk,
    ca.ca_state AS state,
    'web' AS channel,
    wr.wr_return_quantity AS qty,
    wr.wr_return_amt_inc_tax AS amt_inc_tax,
    wr.wr_net_loss AS net_loss,
    wr.wr_returned_date_sk AS date_sk
  FROM web_returns wr
  JOIN customer_address ca
    ON wr.wr_returning_addr_sk = ca.ca_address_sk
)
SELECT
  i.i_category AS category,
  r.state,
  r.channel,
  COUNT(*) AS return_cnt,
  SUM(r.qty) AS total_qty,
  SUM(r.amt_inc_tax) AS total_return_amount_inc_tax,
  SUM(r.net_loss) AS total_net_loss,
  AVG(r.qty) AS avg_qty_per_return,
  SUM(pc.total_promo_cost) AS total_promo_cost
FROM returns r
JOIN item i
  ON r.item_sk = i.i_item_sk
LEFT JOIN promo_cost pc
  ON i.i_item_sk = pc.p_item_sk
WHERE r.date_sk BETWEEN 2450800 AND 2451200
GROUP BY i.i_category, r.state, r.channel
HAVING SUM(r.net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100

WITH returns_union AS (
  SELECT
    i.i_category AS category,
    ca.ca_state AS state,
    cr.cr_net_loss AS net_loss,
    cr.cr_refunded_cash AS refunded_cash,
    cr.cr_return_quantity AS return_quantity
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2450997 AND 2451088
    AND i.i_category IN ('Electronics', 'Furniture', 'Clothing')
  UNION ALL
  SELECT
    i.i_category AS category,
    ca.ca_state AS state,
    sr.sr_net_loss AS net_loss,
    sr.sr_refunded_cash AS refunded_cash,
    sr.sr_return_quantity AS return_quantity
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  WHERE sr.sr_returned_date_sk BETWEEN 2450997 AND 2451088
    AND i.i_category IN ('Electronics', 'Furniture', 'Clothing')
  UNION ALL
  SELECT
    i.i_category AS category,
    ca.ca_state AS state,
    wr.wr_net_loss AS net_loss,
    wr.wr_refunded_cash AS refunded_cash,
    wr.wr_return_quantity AS return_quantity
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
  WHERE wr.wr_returned_date_sk BETWEEN 2450997 AND 2451088
    AND i.i_category IN ('Electronics', 'Furniture', 'Clothing')
)
SELECT
  category,
  state,
  SUM(net_loss) AS total_net_loss,
  SUM(refunded_cash) AS total_refunded_cash,
  SUM(return_quantity) AS total_return_quantity
FROM returns_union
GROUP BY category, state
HAVING SUM(net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100

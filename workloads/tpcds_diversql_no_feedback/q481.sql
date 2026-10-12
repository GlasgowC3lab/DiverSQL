SELECT
  wr_order_number,
  wr_return_tax,
  wr_return_amt,
  wr_net_loss
FROM tpcds.web_returns
WHERE wr_return_tax > 20.00
  AND wr_order_number IN (13, 22, 30)

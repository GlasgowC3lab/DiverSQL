SELECT i.i_product_name,
       i.i_current_price,
       SUM(wr.wr_return_quantity) AS total_return_qty,
       SUM(wr.wr_return_amt) AS total_return_amt
FROM tpcds.item i
JOIN tpcds.web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
WHERE i.i_current_price > 1.85
  AND i.i_manufact_id = 86
  AND wr.wr_fee > 20.0
GROUP BY i.i_product_name, i.i_current_price
ORDER BY total_return_amt DESC
LIMIT 10

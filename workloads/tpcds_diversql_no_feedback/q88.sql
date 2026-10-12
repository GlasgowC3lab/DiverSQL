SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_return_ship_cost
FROM tpcds.web_returns AS wr
JOIN tpcds.item AS i
  ON wr.wr_item_sk = i.i_item_sk
WHERE i.i_current_price > 10.61
  AND wr.wr_return_ship_cost < 382.20
LIMIT 100

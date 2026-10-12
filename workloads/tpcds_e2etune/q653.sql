SELECT
    sr.sr_item_sk AS item_sk,
    sr.sr_reason_sk AS store_reason_sk,
    SUM(sr.sr_return_amt_inc_tax) AS store_total_return_inc_tax,
    SUM(wr.wr_return_amt_inc_tax) AS web_total_return_inc_tax,
    SUM(sr.sr_return_quantity) AS store_total_qty,
    SUM(wr.wr_return_quantity) AS web_total_qty,
    AVG(sr.sr_return_tax) AS store_avg_return_tax,
    AVG(wr.wr_return_tax) AS web_avg_return_tax,
    SUM(sr.sr_net_loss) - SUM(wr.wr_net_loss) AS net_loss_diff,
    CASE WHEN SUM(wr.wr_return_amt_inc_tax) = 0 THEN NULL ELSE SUM(sr.sr_return_amt_inc_tax) / SUM(wr.wr_return_amt_inc_tax) END AS store_to_web_ratio
FROM store_returns sr
JOIN web_returns wr
  ON sr.sr_item_sk = wr.wr_item_sk
  AND sr.sr_returned_date_sk = wr.wr_returned_date_sk
WHERE sr.sr_return_ship_cost > 0
  AND wr.wr_return_ship_cost > 0
  AND sr.sr_return_tax > 50.0
  AND wr.wr_return_tax < 30.0
GROUP BY sr.sr_item_sk, sr.sr_reason_sk
HAVING SUM(sr.sr_return_amt_inc_tax) > 500
   AND SUM(wr.wr_return_amt_inc_tax) > 500
   AND COUNT(*) > 10
ORDER BY store_to_web_ratio DESC
LIMIT 100

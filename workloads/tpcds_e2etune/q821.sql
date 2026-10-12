WITH daily_store_metrics AS (
  SELECT
    sr.sr_store_sk,
    sr.sr_returned_date_sk,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    SUM(sr.sr_net_loss) / NULLIF(SUM(ss.ss_net_profit), 0) AS loss_to_profit_ratio,
    COUNT(*) AS return_count,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    SUM(ss.ss_quantity) AS total_quantity_sold
  FROM store_returns sr
  JOIN store_sales ss
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  WHERE sr.sr_return_tax > 10
    AND sr.sr_returned_date_sk BETWEEN 2451000 AND 2453000
  GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk
  HAVING SUM(sr.sr_net_loss) > 50
)
SELECT
  dsm.sr_store_sk,
  dsm.sr_returned_date_sk,
  dsm.total_return_loss,
  dsm.total_sales_profit,
  dsm.loss_to_profit_ratio,
  dsm.return_count,
  dsm.avg_return_quantity,
  dsm.total_quantity_sold,
  ROW_NUMBER() OVER (PARTITION BY dsm.sr_store_sk ORDER BY dsm.loss_to_profit_ratio DESC) AS rank_by_loss_ratio
FROM daily_store_metrics dsm
ORDER BY dsm.loss_to_profit_ratio DESC
LIMIT 100

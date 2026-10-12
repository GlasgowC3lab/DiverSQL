WITH sales_with_time AS (
  SELECT
    ss.ss_item_sk,
    ss.ss_ticket_number,
    ss.ss_net_profit,
    t.t_time_id,
    t.t_shift,
    t.t_am_pm
  FROM store_sales ss
  JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  WHERE regexp_like(t.t_time_id, '^0[0-9]{3}$')
    AND t.t_shift LIKE 'first%'
)
SELECT
  swt.t_time_id,
  swt.t_shift,
  regexp_extract(swt.t_time_id, '(\\d{2})(\\d{2})', 1) AS hour_part,
  SUM(swt.ss_net_profit)                         AS total_net_profit,
  COUNT(DISTINCT swt.ss_ticket_number)           AS distinct_sales,
  SUM(COALESCE(sr.sr_return_amt, 0))             AS total_return_amount
FROM sales_with_time swt
LEFT JOIN store_returns sr
  ON sr.sr_item_sk = swt.ss_item_sk
  AND sr.sr_ticket_number = swt.ss_ticket_number
WHERE EXISTS (
  SELECT 1
  FROM catalog_returns cr
  WHERE cr.cr_item_sk = swt.ss_item_sk
    AND cr.cr_warehouse_sk = 13
)
GROUP BY
  swt.t_time_id,
  swt.t_shift,
  regexp_extract(swt.t_time_id, '(\\d{2})(\\d{2})', 1)
ORDER BY total_net_profit DESC
LIMIT 100

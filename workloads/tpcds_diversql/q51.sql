WITH
  filtered_returns AS (
    SELECT
      sr.sr_hdemo_sk,
      sr.sr_item_sk,
      sr.sr_ticket_number,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_store_credit
    FROM tpcds.store_returns AS sr
    WHERE sr.sr_store_credit > 5.00
      AND sr.sr_return_quantity <= 2
      AND sr.sr_ticket_number IN (3, 12, 16, 18)
      AND sr.sr_return_amt >= 10.00
  ),
  intersect_items AS (
    SELECT sr_item_sk FROM filtered_returns WHERE sr_return_quantity = 1
    INTERSECT
    SELECT sr_item_sk FROM filtered_returns WHERE sr_store_credit < 10.00
  )
SELECT DISTINCT
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  COUNT(*) AS cnt_returns,
  SUM(fr.sr_return_amt) AS total_return_amt,
  AVG(fr.sr_return_amt) AS avg_return_amt,
  MIN(fr.sr_return_amt) AS min_return_amt,
  MAX(fr.sr_return_amt) AS max_return_amt
FROM filtered_returns AS fr
JOIN tpcds.household_demographics AS hd
  ON fr.sr_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band AS ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_vehicle_count = 0
  AND ib.ib_lower_bound >= 100001
  AND NOT EXISTS (
    SELECT 1 FROM tpcds.store_returns AS sr2
    WHERE sr2.sr_ticket_number = fr.sr_ticket_number
      AND sr2.sr_item_sk <> fr.sr_item_sk
  )
  AND fr.sr_item_sk IN (SELECT sr_item_sk FROM intersect_items)
GROUP BY hd.hd_buy_potential, ib.ib_lower_bound
ORDER BY total_return_amt DESC
LIMIT 100

SELECT
    i.i_category,
    hd_ret.hd_income_band_sk AS returning_income_band,
    hd_ret.hd_vehicle_count AS returning_vehicle_count,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    COUNT(*) AS return_cnt
FROM catalog_returns cr
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN household_demographics hd_ret
  ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN household_demographics hd_ref
  ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
WHERE cr.cr_store_credit > 50
  AND cr.cr_returned_date_sk BETWEEN 2458848 AND 2459212
  AND i.i_category IS NOT NULL
GROUP BY
    i.i_category,
    hd_ret.hd_income_band_sk,
    hd_ret.hd_vehicle_count
HAVING SUM(cr.cr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 10

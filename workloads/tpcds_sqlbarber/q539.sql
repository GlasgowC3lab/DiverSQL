SELECT hd.hd_income_band_sk,
       cr.cr_returned_date_sk,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(*) AS return_count
FROM catalog_returns cr
JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE cr.cr_returned_date_sk BETWEEN 2450969 AND 2450969
GROUP BY hd.hd_income_band_sk, cr.cr_returned_date_sk

SELECT hd.hd_demo_sk,
       ib.ib_income_band_sk,
       COUNT(*) AS return_count
FROM store_sales ss
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN catalog_returns cr ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss2
    WHERE ss2.ss_hdemo_sk = hd.hd_demo_sk
      AND ss2.ss_sold_date_sk = 2450872
)
GROUP BY hd.hd_demo_sk, ib.ib_income_band_sk
HAVING SUM(cr.cr_return_amount) > 5100.48

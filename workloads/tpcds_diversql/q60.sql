SELECT sr_store_sk,
       COUNT(*) AS returns_count,
       SUM(sr_return_amt_inc_tax) AS total_return_inc_tax,
       AVG(sr_return_quantity) AS avg_quantity
FROM tpcds.store_returns
WHERE sr_return_time_sk = 51589
  AND sr_return_amt_inc_tax > 500
GROUP BY sr_store_sk
ORDER BY total_return_inc_tax DESC
LIMIT 10

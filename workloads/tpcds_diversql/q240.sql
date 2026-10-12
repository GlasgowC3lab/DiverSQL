SELECT
  wr_returning_cdemo_sk,
  COUNT(*) AS return_cnt,
  SUM(wr_return_amt) AS total_return_amount,
  AVG(wr_return_tax) AS avg_return_tax
FROM tpcds.web_returns
WHERE wr_returning_cdemo_sk = 1176118
  AND wr_return_tax > 20.00
GROUP BY wr_returning_cdemo_sk
ORDER BY total_return_amount DESC

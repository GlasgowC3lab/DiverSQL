WITH combined_returns AS (
  SELECT 'store' AS channel,
         sr.sr_return_amt AS return_amt,
         sr.sr_net_loss AS net_loss,
         sr.sr_cdemo_sk AS cdemo_sk,
         sr.sr_reason_sk AS reason_sk
  FROM store_returns sr
  WHERE sr.sr_returned_date_sk BETWEEN 2450815 AND 2451088
  UNION ALL
  SELECT 'web' AS channel,
         wr.wr_return_amt AS return_amt,
         wr.wr_net_loss AS net_loss,
         wr.wr_refunded_cdemo_sk AS cdemo_sk,
         wr.wr_reason_sk AS reason_sk
  FROM web_returns wr
  WHERE wr.wr_returned_date_sk BETWEEN 2450815 AND 2451088
),
agg AS (
  SELECT cr.channel,
         r.r_reason_desc AS reason_desc,
         cd.cd_gender AS gender,
         SUM(cr.net_loss) AS total_net_loss,
         SUM(cr.return_amt) AS total_return_amt,
         COUNT(*) AS total_returns
  FROM combined_returns cr
  JOIN customer_demographics cd ON cr.cdemo_sk = cd.cd_demo_sk
  JOIN reason r ON cr.reason_sk = r.r_reason_sk
  WHERE cd.cd_gender IN ('M', 'F')
  GROUP BY cr.channel, r.r_reason_desc, cd.cd_gender
)
SELECT channel,
       reason_desc,
       gender,
       total_net_loss,
       total_return_amt,
       total_returns,
       RANK() OVER (PARTITION BY channel ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY channel, net_loss_rank
LIMIT 200

SELECT time_sk,
       wp_type,
       total_loss,
       total_profit,
       net_diff,
       CASE WHEN net_loss_ratio > 1 THEN 'Loss > Profit' ELSE 'Profit >= Loss' END AS loss_profit_flag,
       DENSE_RANK() OVER (ORDER BY net_diff DESC) AS overall_net_diff_rank,
       SUM(total_loss) OVER (PARTITION BY wp_type) AS total_loss_by_type,
       SUM(total_profit) OVER (PARTITION BY wp_type) AS total_profit_by_type
FROM (
  SELECT cr.cr_returned_time_sk AS time_sk,
         wp.wp_type,
         SUM(cr.cr_net_loss) AS total_loss,
         SUM(ws.ws_net_profit) AS total_profit,
         SUM(cr.cr_net_loss) - SUM(ws.ws_net_profit) AS net_diff,
         (SUM(cr.cr_net_loss) / NULLIF(SUM(ws.ws_net_profit),0)) AS net_loss_ratio
  FROM catalog_returns cr
  JOIN web_sales ws ON cr.cr_returned_time_sk = ws.ws_sold_time_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  GROUP BY cr.cr_returned_time_sk, wp.wp_type
  HAVING SUM(cr.cr_net_loss) > 1000
) sub
ORDER BY net_diff DESC
LIMIT 50

SELECT time_sk,
       wp_type,
       total_loss,
       total_profit,
       net_diff,
       CASE WHEN net_diff > 0 THEN 'Loss exceeds profit' ELSE 'Profit exceeds loss' END AS diff_category,
       ROW_NUMBER() OVER (PARTITION BY wp_type ORDER BY time_sk) AS row_num_by_type,
       SUM(total_loss) OVER (PARTITION BY wp_type ORDER BY time_sk ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS future_cum_loss,
       SUM(total_profit) OVER (PARTITION BY wp_type ORDER BY time_sk ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS future_cum_profit
FROM (
  SELECT cr.cr_returned_time_sk AS time_sk,
         wp.wp_type,
         SUM(cr.cr_net_loss) AS total_loss,
         SUM(ws.ws_net_profit) AS total_profit,
         SUM(cr.cr_net_loss) - SUM(ws.ws_net_profit) AS net_diff
  FROM catalog_returns cr
  JOIN web_sales ws ON cr.cr_returned_time_sk = ws.ws_sold_time_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE wp.wp_type IS NOT NULL
  GROUP BY cr.cr_returned_time_sk, wp.wp_type
) sub
WHERE time_sk BETWEEN 20000101 AND 20001231
ORDER BY wp_type, time_sk

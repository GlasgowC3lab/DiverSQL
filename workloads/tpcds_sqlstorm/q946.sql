WITH sales AS (
    SELECT 'store' AS channel, ss.ss_sold_date_sk AS date_sk, ss.ss_net_profit AS net_profit, 0 AS net_loss
    FROM store_sales ss
    UNION ALL
    SELECT 'web', ws.ws_sold_date_sk, ws.ws_net_profit, 0
    FROM web_sales ws
    UNION ALL
    SELECT 'catalog', cs.cs_sold_date_sk, cs.cs_net_profit, 0
    FROM catalog_sales cs
), returns AS (
    SELECT 'store' AS channel, sr.sr_returned_date_sk AS date_sk, 0 AS net_profit, sr.sr_net_loss AS net_loss
    FROM store_returns sr
    UNION ALL
    SELECT 'web', wr.wr_returned_date_sk, 0, wr.wr_net_loss
    FROM web_returns wr
    UNION ALL
    SELECT 'catalog', cr.cr_returned_date_sk, 0, cr.cr_net_loss
    FROM catalog_returns cr
), combined AS (
    SELECT channel, date_sk, SUM(net_profit) AS net_profit, SUM(net_loss) AS net_loss
    FROM (
        SELECT * FROM sales
        UNION ALL
        SELECT * FROM returns
    ) t
    GROUP BY channel, date_sk
)
SELECT d.d_year,
       d.d_month_seq,
       c.channel,
       SUM(c.net_profit) AS total_profit,
       SUM(c.net_loss) AS total_loss,
       CASE WHEN SUM(c.net_profit) = 0 THEN 0 ELSE SUM(c.net_loss) / SUM(c.net_profit) END AS loss_to_profit_ratio
FROM combined c
JOIN date_dim d ON c.date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2001
GROUP BY d.d_year, d.d_month_seq, c.channel
ORDER BY d.d_year, d.d_month_seq, total_profit DESC
LIMIT 100

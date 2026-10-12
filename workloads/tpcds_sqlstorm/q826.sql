SELECT d.d_year,
       i.i_category,
       SUM(t.net_profit) AS total_sales_profit,
       SUM(t.return_loss) AS total_return_loss,
       SUM(t.net_profit) - SUM(t.return_loss) AS net_profit_after_returns
FROM (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_profit AS net_profit,
           CAST(0 AS decimal(7,2)) AS return_loss
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_net_profit,
           CAST(0 AS decimal(7,2))
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_net_profit,
           CAST(0 AS decimal(7,2))
    FROM web_sales ws
    UNION ALL
    SELECT cr.cr_returned_date_sk,
           cr.cr_item_sk,
           CAST(0 AS decimal(7,2)),
           cr.cr_net_loss
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_returned_date_sk,
           sr.sr_item_sk,
           CAST(0 AS decimal(7,2)),
           sr.sr_net_loss
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           wr.wr_item_sk,
           CAST(0 AS decimal(7,2)),
           wr.wr_net_loss
    FROM web_returns wr
) t
JOIN date_dim d ON t.date_sk = d.d_date_sk
JOIN item i ON t.item_sk = i.i_item_sk
GROUP BY d.d_year, i.i_category
ORDER BY d.d_year, i.i_category

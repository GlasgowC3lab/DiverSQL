SELECT d.d_year,
       COALESCE(SUM(ss.ss_net_profit), 0) AS store_net_profit,
       COALESCE(SUM(cs.cs_net_profit), 0) AS catalog_net_profit,
       COALESCE(SUM(ws.ws_net_profit), 0) AS web_net_profit,
       COALESCE(SUM(sr.sr_net_loss), 0) AS store_return_loss,
       COALESCE(SUM(cr.cr_net_loss), 0) AS catalog_return_loss,
       COALESCE(SUM(wr.wr_net_loss), 0) AS web_return_loss
FROM date_dim d
LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
GROUP BY d.d_year
ORDER BY d.d_year

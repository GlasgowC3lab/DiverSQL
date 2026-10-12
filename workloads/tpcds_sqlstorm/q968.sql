SELECT d.d_year,
       x.state,
       SUM(x.net_profit) AS total_net_profit
FROM (
    SELECT ss.ss_sold_date_sk AS date_sk,
           s.s_state AS state,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk

    UNION ALL

    SELECT ws.ws_sold_date_sk AS date_sk,
           w.web_state AS state,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk

    UNION ALL

    SELECT cs.cs_sold_date_sk AS date_sk,
           cc.cc_state AS state,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
) x
JOIN date_dim d ON x.date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2002
GROUP BY d.d_year, x.state
ORDER BY d.d_year, x.state

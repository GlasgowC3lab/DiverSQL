SELECT d.d_year,
       unified.state,
       SUM(unified.net_profit) AS total_net_profit,
       COUNT(*) AS total_transactions
FROM (
    SELECT ss.ss_sold_date_sk AS sold_date_sk,
           s.s_state AS state,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    UNION ALL
    SELECT cs.cs_sold_date_sk AS sold_date_sk,
           cc.cc_state AS state,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    UNION ALL
    SELECT ws.ws_sold_date_sk AS sold_date_sk,
           ws_site.web_state AS state,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
) unified
JOIN date_dim d ON unified.sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1998 AND 1999
GROUP BY d.d_year, unified.state
ORDER BY d.d_year, unified.state

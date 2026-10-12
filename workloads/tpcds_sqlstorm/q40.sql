WITH sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_net_profit AS net_profit,
           'catalog' AS channel,
           cc.cc_state AS state,
           d.d_year AS year
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_net_profit AS net_profit,
           'store' AS channel,
           s.s_state AS state,
           d.d_year AS year
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT ws.ws_sold_date_sk AS date_sk,
           ws.ws_net_profit AS net_profit,
           'web' AS channel,
           wsite.web_state AS state,
           d.d_year AS year
    FROM web_sales ws
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT channel,
       state,
       SUM(net_profit) AS total_net_profit,
       COUNT(*) AS transaction_count
FROM sales
GROUP BY channel, state
ORDER BY total_net_profit DESC

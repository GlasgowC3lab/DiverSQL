SELECT
    t.year,
    t.state,
    SUM(t.net_profit) AS total_net_profit
FROM (
    SELECT d.d_year AS year,
           s.s_state AS state,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk

    UNION ALL

    SELECT d.d_year AS year,
           cc.cc_state AS state,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk

    UNION ALL

    SELECT d.d_year AS year,
           w.web_state AS state,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
) t
GROUP BY t.year, t.state
ORDER BY t.year, t.state

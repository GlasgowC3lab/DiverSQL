WITH store_agg AS (
    SELECT d.d_year AS year,
           s.s_state AS state,
           SUM(ss.ss_net_paid) AS net_paid,
           SUM(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY d.d_year, s.s_state
),
web_agg AS (
    SELECT d.d_year AS year,
           w.web_state AS state,
           SUM(ws.ws_net_paid) AS net_paid,
           SUM(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY d.d_year, w.web_state
),
catalog_agg AS (
    SELECT d.d_year AS year,
           cc.cc_state AS state,
           SUM(cs.cs_net_paid) AS net_paid,
           SUM(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY d.d_year, cc.cc_state
)
SELECT year,
       state,
       total_net_paid,
       total_net_profit,
       RANK() OVER (PARTITION BY year ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT year,
           state,
           SUM(net_paid) AS total_net_paid,
           SUM(net_profit) AS total_net_profit
    FROM (
        SELECT * FROM store_agg
        UNION ALL
        SELECT * FROM web_agg
        UNION ALL
        SELECT * FROM catalog_agg
    ) AS combined
    GROUP BY year, state
) AS aggregated
ORDER BY year, profit_rank

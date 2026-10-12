WITH store_sales_agg AS (
    SELECT s.s_state AS state,
           d.d_year AS yr,
           sum(ss.ss_net_profit) AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_state, d.d_year
),
web_sales_agg AS (
    SELECT ws_site.web_state AS state,
           d.d_year AS yr,
           sum(ws.ws_net_profit) AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    GROUP BY ws_site.web_state, d.d_year
),
catalog_sales_agg AS (
    SELECT cc.cc_state AS state,
           d.d_year AS yr,
           sum(cs.cs_net_profit) AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY cc.cc_state, d.d_year
)
SELECT state,
       yr,
       sum(net_profit) AS total_net_profit
FROM (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
) agg
GROUP BY state, yr
ORDER BY total_net_profit DESC
LIMIT 100

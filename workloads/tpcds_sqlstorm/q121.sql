WITH combined_sales AS (
    SELECT d.d_year AS year, s.s_state AS state, ss.ss_net_profit AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    UNION ALL
    SELECT d.d_year AS year, ws_site.web_state AS state, ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    UNION ALL
    SELECT d.d_year AS year, cc.cc_state AS state, cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
)
SELECT year, state, total_profit
FROM (
    SELECT year, state, total_profit,
           rank() OVER (PARTITION BY year ORDER BY total_profit DESC) AS rnk
    FROM (
        SELECT year, state, SUM(profit) AS total_profit
        FROM combined_sales
        GROUP BY year, state
    ) agg
) ranked
WHERE rnk <= 10
ORDER BY year, rnk

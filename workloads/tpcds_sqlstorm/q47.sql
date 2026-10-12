WITH store_sales_agg AS (
    SELECT d.d_year AS year,
           s.s_state AS state,
           SUM(ss.ss_net_paid) AS store_sales,
           SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY d.d_year, s.s_state
),
catalog_sales_agg AS (
    SELECT d.d_year AS year,
           cc.cc_state AS state,
           SUM(cs.cs_net_paid) AS catalog_sales,
           SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY d.d_year, cc.cc_state
),
web_sales_agg AS (
    SELECT d.d_year AS year,
           ws.web_state AS state,
           SUM(w.ws_net_paid) AS web_sales,
           SUM(w.ws_net_profit) AS web_profit
    FROM web_sales w
    JOIN date_dim d ON w.ws_sold_date_sk = d.d_date_sk
    JOIN web_site ws ON w.ws_web_site_sk = ws.web_site_sk
    GROUP BY d.d_year, ws.web_state
)
SELECT
    year,
    state,
    COALESCE(store_sales, 0) + COALESCE(catalog_sales, 0) + COALESCE(web_sales, 0) AS total_sales,
    COALESCE(store_profit, 0) + COALESCE(catalog_profit, 0) + COALESCE(web_profit, 0) AS total_profit
FROM store_sales_agg s
FULL OUTER JOIN catalog_sales_agg c USING (year, state)
FULL OUTER JOIN web_sales_agg w USING (year, state)
ORDER BY total_sales DESC
LIMIT 100

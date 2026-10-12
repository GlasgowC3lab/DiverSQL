WITH store_agg AS (
    SELECT d.d_year AS year, SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year
),
catalog_agg AS (
    SELECT d.d_year AS year, SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year
),
web_agg AS (
    SELECT d.d_year AS year, SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year
)
SELECT
    COALESCE(s.year, c.year, w.year) AS year,
    s.store_profit,
    c.catalog_profit,
    w.web_profit,
    COALESCE(s.store_profit, 0) + COALESCE(c.catalog_profit, 0) + COALESCE(w.web_profit, 0) AS total_profit
FROM store_agg s
FULL OUTER JOIN catalog_agg c ON s.year = c.year
FULL OUTER JOIN web_agg w ON COALESCE(s.year, c.year) = w.year
ORDER BY year

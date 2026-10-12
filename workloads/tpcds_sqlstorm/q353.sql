WITH catalog AS (
    SELECT d.d_year, d.d_moy,
           SUM(cs.cs_net_paid) AS catalog_sales,
           SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_moy
), store AS (
    SELECT d.d_year, d.d_moy,
           SUM(ss.ss_net_paid) AS store_sales,
           SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_moy
), web AS (
    SELECT d.d_year, d.d_moy,
           SUM(ws.ws_net_paid) AS web_sales,
           SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_moy
)
SELECT c.d_year,
       c.d_moy,
       c.catalog_sales,
       c.catalog_profit,
       s.store_sales,
       s.store_profit,
       w.web_sales,
       w.web_profit,
       (c.catalog_sales + s.store_sales + w.web_sales) AS total_sales,
       (c.catalog_profit + s.store_profit + w.web_profit) AS total_profit
FROM catalog c
JOIN store s ON c.d_year = s.d_year AND c.d_moy = s.d_moy
JOIN web w ON c.d_year = w.d_year AND c.d_moy = w.d_moy
ORDER BY c.d_year, c.d_moy

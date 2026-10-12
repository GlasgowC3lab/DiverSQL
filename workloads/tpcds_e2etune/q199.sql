WITH store_profit AS (
  SELECT d.d_year,
         cd.cd_gender,
         cd.cd_marital_status,
         SUM(ss.ss_net_profit) AS store_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  GROUP BY d.d_year, cd.cd_gender, cd.cd_marital_status
),
web_profit AS (
  SELECT d.d_year,
         cd.cd_gender,
         cd.cd_marital_status,
         SUM(ws.ws_net_profit) AS web_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  GROUP BY d.d_year, cd.cd_gender, cd.cd_marital_status
),
combined AS (
  SELECT COALESCE(sp.d_year, wp.d_year) AS d_year,
         COALESCE(sp.cd_gender, wp.cd_gender) AS cd_gender,
         COALESCE(sp.cd_marital_status, wp.cd_marital_status) AS cd_marital_status,
         COALESCE(sp.store_profit, 0) AS store_profit,
         COALESCE(wp.web_profit, 0) AS web_profit,
         COALESCE(sp.store_profit, 0) + COALESCE(wp.web_profit, 0) AS total_profit
  FROM store_profit sp
  FULL OUTER JOIN web_profit wp
    ON sp.d_year = wp.d_year
   AND sp.cd_gender = wp.cd_gender
   AND sp.cd_marital_status = wp.cd_marital_status
)
SELECT d_year,
       cd_gender,
       cd_marital_status,
       total_profit,
       LAG(total_profit) OVER (PARTITION BY cd_gender, cd_marital_status ORDER BY d_year) AS prev_year_profit,
       CASE
         WHEN LAG(total_profit) OVER (PARTITION BY cd_gender, cd_marital_status ORDER BY d_year) IS NULL THEN NULL
         ELSE (total_profit - LAG(total_profit) OVER (PARTITION BY cd_gender, cd_marital_status ORDER BY d_year))
              / LAG(total_profit) OVER (PARTITION BY cd_gender, cd_marital_status ORDER BY d_year) * 100
       END AS profit_growth_pct
FROM combined
WHERE total_profit > 10000
ORDER BY total_profit DESC
LIMIT 100

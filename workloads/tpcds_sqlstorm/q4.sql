WITH ss AS (
  SELECT d.d_year,
         i.i_category,
         SUM(ss.ss_net_profit) AS profit,
         SUM(ss.ss_quantity) AS quantity,
         COUNT(DISTINCT ss.ss_customer_sk) AS customers
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
  GROUP BY d.d_year, i.i_category
),
cs AS (
  SELECT d.d_year,
         i.i_category,
         SUM(cs.cs_net_profit) AS profit,
         SUM(cs.cs_quantity) AS quantity,
         COUNT(DISTINCT cs.cs_bill_customer_sk) AS customers
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
  GROUP BY d.d_year, i.i_category
),
ws AS (
  SELECT d.d_year,
         i.i_category,
         SUM(ws.ws_net_profit) AS profit,
         SUM(ws.ws_quantity) AS quantity,
         COUNT(DISTINCT ws.ws_bill_customer_sk) AS customers
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
  GROUP BY d.d_year, i.i_category
)
SELECT
  year,
  category,
  SUM(profit) AS total_profit,
  SUM(quantity) AS total_quantity,
  SUM(customers) AS distinct_customers
FROM (
  SELECT d_year AS year, i_category AS category, profit, quantity, customers FROM ss
  UNION ALL
  SELECT d_year, i_category, profit, quantity, customers FROM cs
  UNION ALL
  SELECT d_year, i_category, profit, quantity, customers FROM ws
) t
GROUP BY year, category
ORDER BY year, category

WITH sales AS (
  SELECT d.d_year,
         d.d_month_seq AS d_month,
         i.i_category,
         i.i_class,
         ss.ss_net_profit AS net_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  UNION ALL
  SELECT d.d_year,
         d.d_month_seq,
         i.i_category,
         i.i_class,
         cs.cs_net_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  UNION ALL
  SELECT d.d_year,
         d.d_month_seq,
         i.i_category,
         i.i_class,
         ws.ws_net_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
agg AS (
  SELECT d_year,
         d_month,
         i_category,
         i_class,
         SUM(net_profit) AS total_net_profit
  FROM sales
  WHERE d_year = 2001
  GROUP BY d_year, d_month, i_category, i_class
),
ranked AS (
  SELECT d_year,
         d_month,
         i_category,
         i_class,
         total_net_profit,
         ROW_NUMBER() OVER (PARTITION BY d_year, d_month ORDER BY total_net_profit DESC) AS rank
  FROM agg
)
SELECT d_year,
       d_month,
       i_category,
       i_class,
       total_net_profit
FROM ranked
WHERE rank <= 10
ORDER BY d_year, d_month, rank

WITH sales AS (
   SELECT
      d.d_year AS year,
      i.i_category AS category,
      i.i_brand AS brand,
      i.i_color AS color,
      ca.ca_state AS state,
      cd.cd_gender AS gender,
      ss.ss_quantity AS quantity,
      ss.ss_net_paid AS net_paid,
      ss.ss_net_profit AS net_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   UNION ALL
   SELECT
      d.d_year,
      i.i_category,
      i.i_brand,
      i.i_color,
      ca.ca_state,
      cd.cd_gender,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_net_profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   UNION ALL
   SELECT
      d.d_year,
      i.i_category,
      i.i_brand,
      i.i_color,
      ca.ca_state,
      cd.cd_gender,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_net_profit
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
)
SELECT
   year,
   category,
   brand,
   color,
   state,
   gender,
   total_quantity,
   total_net_paid,
   total_net_profit,
   avg_profit_margin,
   ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_net_profit DESC) AS profit_rank
FROM (
   SELECT
      year,
      category,
      brand,
      color,
      state,
      gender,
      SUM(quantity) AS total_quantity,
      SUM(net_paid) AS total_net_paid,
      SUM(net_profit) AS total_net_profit,
      AVG(CASE WHEN net_paid = 0 THEN NULL ELSE net_profit / net_paid END) AS avg_profit_margin
   FROM sales
   WHERE year BETWEEN 1999 AND 2002
     AND state IS NOT NULL
   GROUP BY year, category, brand, color, state, gender
   HAVING SUM(net_profit) > 0
) agg
ORDER BY total_net_profit DESC
LIMIT 100

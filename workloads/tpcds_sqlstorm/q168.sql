WITH combined_sales AS (
  SELECT d.d_year AS year,
         s.s_state AS state,
         ss.ss_net_profit AS net_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE i.i_category = 'Books'
  UNION ALL
  SELECT d.d_year AS year,
         cc.cc_state AS state,
         cs.cs_net_profit AS net_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i2 ON cs.cs_item_sk = i2.i_item_sk
  WHERE i2.i_category = 'Books'
  UNION ALL
  SELECT d.d_year AS year,
         w.web_state AS state,
         ws.ws_net_profit AS net_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  JOIN item i3 ON ws.ws_item_sk = i3.i_item_sk
  WHERE i3.i_category = 'Books'
),
agg AS (
  SELECT year,
         state,
         sum(net_profit) AS total_net_profit,
         count(*) AS transaction_cnt,
         avg(net_profit) AS avg_net_profit
  FROM combined_sales
  WHERE year = 2002
  GROUP BY year, state
  HAVING sum(net_profit) > 0
)
SELECT year,
       state,
       total_net_profit,
       transaction_cnt,
       avg_net_profit,
       row_number() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY total_net_profit DESC
LIMIT 50

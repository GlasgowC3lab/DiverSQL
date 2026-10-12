WITH combined_sales AS (
   SELECT d.d_year, d.d_month_seq, i.i_category, ss.ss_net_profit AS net_profit, 'store' AS channel
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   UNION ALL
   SELECT d.d_year, d.d_month_seq, i.i_category, ws.ws_net_profit, 'web'
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   UNION ALL
   SELECT d.d_year, d.d_month_seq, i.i_category, cs.cs_net_profit, 'catalog'
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
), agg_profit AS (
   SELECT d_year, d_month_seq, i_category, channel, SUM(net_profit) AS total_net_profit
   FROM combined_sales
   GROUP BY d_year, d_month_seq, i_category, channel
), ranked_profit AS (
   SELECT d_year, d_month_seq, i_category, channel, total_net_profit,
          ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq, channel ORDER BY total_net_profit DESC) AS rank_in_month
   FROM agg_profit
)
SELECT d_year, d_month_seq, channel, i_category, total_net_profit
FROM ranked_profit
WHERE rank_in_month <= 10
ORDER BY d_year, d_month_seq, channel, rank_in_month

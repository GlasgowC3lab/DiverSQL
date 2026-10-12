WITH store_sales_agg AS (
   SELECT
      d.d_year,
      d.d_quarter_seq,
      i.i_category,
      cd.cd_gender,
      'store' AS channel,
      ss.ss_net_profit AS net_profit,
      ss.ss_quantity AS quantity,
      ss.ss_ext_sales_price AS ext_sales,
      i.i_item_id,
      i.i_item_sk
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
), 
catalog_sales_agg AS (
   SELECT
      d.d_year,
      d.d_quarter_seq,
      i.i_category,
      cd.cd_gender,
      'catalog' AS channel,
      cs.cs_net_profit AS net_profit,
      cs.cs_quantity AS quantity,
      cs.cs_ext_sales_price AS ext_sales,
      i.i_item_id,
      i.i_item_sk
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
), 
web_sales_agg AS (
   SELECT
      d.d_year,
      d.d_quarter_seq,
      i.i_category,
      cd.cd_gender,
      'web' AS channel,
      ws.ws_net_profit AS net_profit,
      ws.ws_quantity AS quantity,
      ws.ws_ext_sales_price AS ext_sales,
      i.i_item_id,
      i.i_item_sk
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   LEFT JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
), 
all_sales AS (
   SELECT * FROM store_sales_agg
   UNION ALL
   SELECT * FROM catalog_sales_agg
   UNION ALL
   SELECT * FROM web_sales_agg
), 
item_profit AS (
   SELECT
      d_year,
      channel,
      i_category,
      i_item_sk,
      i_item_id,
      SUM(net_profit) AS item_net_profit
   FROM all_sales
   GROUP BY d_year, channel, i_category, i_item_sk, i_item_id
), 
top_item_per_category AS (
   SELECT
      d_year,
      channel,
      i_category,
      i_item_id,
      item_net_profit
   FROM (
      SELECT
         d_year,
         channel,
         i_category,
         i_item_id,
         item_net_profit,
         ROW_NUMBER() OVER (PARTITION BY d_year, channel, i_category ORDER BY item_net_profit DESC) AS rn
      FROM item_profit
   ) t
   WHERE rn = 1
), 
aggregated AS (
   SELECT
      d_year,
      d_quarter_seq,
      channel,
      i_category,
      cd_gender,
      SUM(net_profit) AS total_net_profit,
      SUM(quantity) AS total_quantity,
      SUM(ext_sales) AS total_ext_sales,
      COUNT(*) AS order_cnt
   FROM all_sales
   GROUP BY d_year, d_quarter_seq, channel, i_category, cd_gender
)
SELECT
   a.d_year,
   a.d_quarter_seq,
   a.channel,
   a.i_category,
   a.cd_gender,
   a.total_net_profit,
   a.total_quantity,
   a.total_ext_sales,
   a.order_cnt,
   DENSE_RANK() OVER (PARTITION BY a.d_year, a.channel ORDER BY a.total_net_profit DESC) AS category_profit_rank,
   t.i_item_id AS top_item_id,
   t.item_net_profit AS top_item_profit
FROM aggregated a
LEFT JOIN top_item_per_category t
   ON a.d_year = t.d_year
   AND a.channel = t.channel
   AND a.i_category = t.i_category
WHERE a.d_year BETWEEN 1999 AND 2002
ORDER BY a.d_year, a.channel, category_profit_rank
LIMIT 200

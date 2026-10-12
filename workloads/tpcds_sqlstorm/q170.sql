WITH sales_union AS (
  SELECT cs_sold_date_sk AS sold_date_sk, cs_item_sk AS item_sk, cs_net_profit AS net_profit, 'catalog' AS channel
  FROM catalog_sales
  UNION ALL
  SELECT ss_sold_date_sk, ss_item_sk, ss_net_profit, 'store'
  FROM store_sales
  UNION ALL
  SELECT ws_sold_date_sk, ws_item_sk, ws_net_profit, 'web'
  FROM web_sales
),
sales_enriched AS (
  SELECT su.sold_date_sk,
         i.i_item_sk,
         i.i_class,
         su.channel,
         su.net_profit,
         d.d_year,
         d.d_moy AS month_num
  FROM sales_union su
  JOIN date_dim d ON su.sold_date_sk = d.d_date_sk
  JOIN item i ON su.item_sk = i.i_item_sk
),
aggregated AS (
  SELECT
    se.d_year,
    se.month_num,
    se.i_class,
    se.channel,
    SUM(se.net_profit) AS total_net_profit,
    AVG(se.net_profit) AS avg_net_profit,
    COUNT(*) AS sales_transactions,
    COUNT(DISTINCT se.i_item_sk) AS distinct_items_sold
  FROM sales_enriched se
  WHERE se.d_year BETWEEN 2000 AND 2002
  GROUP BY se.d_year, se.month_num, se.i_class, se.channel
)
SELECT
  a.d_year,
  a.month_num,
  a.i_class,
  a.channel,
  a.total_net_profit,
  a.avg_net_profit,
  a.sales_transactions,
  a.distinct_items_sold,
  RANK() OVER (PARTITION BY a.d_year, a.month_num ORDER BY a.total_net_profit DESC) AS profit_rank_by_class_channel
FROM aggregated a
ORDER BY a.d_year, a.month_num, a.total_net_profit DESC
LIMIT 100

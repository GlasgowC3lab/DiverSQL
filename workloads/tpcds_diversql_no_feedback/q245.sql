WITH
  catalog_data AS (
    SELECT
      i.i_category,
      td.t_hour,
      'catalog' AS sales_channel,
      cs.cs_net_profit AS net_profit,
      cs.cs_quantity AS qty
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_net_profit > 0
      AND i.i_rec_end_date = DATE '2000-10-26'
      AND td.t_meal_time = 'Lunch'
  ),
  store_data AS (
    SELECT
      i.i_category,
      td.t_hour,
      'store' AS sales_channel,
      ss.ss_net_profit AS net_profit,
      ss.ss_quantity AS qty
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE ss.ss_net_profit > 0
      AND i.i_rec_end_date = DATE '2000-10-26'
      AND td.t_meal_time = 'Lunch'
  ),
  combined AS (
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM store_data
  )
SELECT
  i_category,
  t_hour,
  sales_channel,
  SUM(net_profit) AS total_net_profit,
  SUM(qty) AS total_quantity
FROM combined
GROUP BY CUBE (i_category, t_hour, sales_channel)
ORDER BY i_category NULLS LAST, t_hour NULLS LAST, sales_channel
LIMIT 100

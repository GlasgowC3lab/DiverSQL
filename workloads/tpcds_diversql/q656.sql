-- Goal: Compare profit performance of items sold through stores and web channels, show subtotals and grand total by category, brand and item, exclude items that appear in large catalog sales, keep only items sold in both channels, and return the top results.
WITH
  store_summary AS (
    SELECT
      i.i_category,
      i.i_brand,
      i.i_item_sk,
      SUM(ss.ss_net_profit) AS net_profit,
      COUNT(*) AS sales_cnt,
      MIN(ss.ss_sold_date_sk) AS first_sold_date_sk
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 17
    GROUP BY ROLLUP(i.i_category, i.i_brand, i.i_item_sk)
  ),
  web_summary AS (
    SELECT
      i.i_category,
      i.i_brand,
      i.i_item_sk,
      SUM(ws.ws_net_profit) AS net_profit,
      COUNT(*) AS sales_cnt,
      MIN(ws.ws_sold_date_sk) AS first_sold_date_sk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 17
    GROUP BY ROLLUP(i.i_category, i.i_brand, i.i_item_sk)
  ),
  union_summary AS (
    SELECT i_category, i_brand, i_item_sk, net_profit, sales_cnt, first_sold_date_sk FROM store_summary
    UNION
    SELECT i_category, i_brand, i_item_sk, net_profit, sales_cnt, first_sold_date_sk FROM web_summary
  ),
  common_items AS (
    SELECT ss_item_sk AS item_sk FROM store_sales
    INTERSECT
    SELECT ws_item_sk FROM web_sales
  )
SELECT
  us.i_category,
  us.i_brand,
  us.i_item_sk,
  SUM(us.net_profit) AS total_profit,
  SUM(us.sales_cnt) AS total_sales,
  MIN(us.first_sold_date_sk) AS earliest_sold_date_sk
FROM union_summary us
WHERE us.i_item_sk NOT IN (
        SELECT cs.cs_item_sk FROM catalog_sales cs WHERE cs.cs_quantity > 1000
      )
  AND us.i_item_sk IN (SELECT ci.item_sk FROM common_items ci)
GROUP BY ROLLUP(us.i_category, us.i_brand, us.i_item_sk)
ORDER BY total_profit DESC
LIMIT 100

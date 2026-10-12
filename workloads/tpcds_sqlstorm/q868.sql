WITH all_sales AS (
  SELECT cs_sold_date_sk AS date_sk, cs_net_profit AS net_profit, cs_quantity AS quantity, 'catalog' AS channel, cs_item_sk AS item_sk
  FROM catalog_sales
  UNION ALL
  SELECT ss_sold_date_sk AS date_sk, ss_net_profit AS net_profit, ss_quantity AS quantity, 'store' AS channel, ss_item_sk AS item_sk
  FROM store_sales
  UNION ALL
  SELECT ws_sold_date_sk AS date_sk, ws_net_profit AS net_profit, ws_quantity AS quantity, 'web' AS channel, ws_item_sk AS item_sk
  FROM web_sales
)
SELECT d.d_year,
       d.d_month_seq,
       s.channel,
       i.i_category,
       SUM(s.net_profit) AS total_net_profit,
       SUM(s.quantity) AS total_quantity
FROM all_sales s
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year, d.d_month_seq, s.channel, i.i_category
ORDER BY d.d_year, d.d_month_seq, s.channel, i.i_category

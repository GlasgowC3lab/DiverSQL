WITH unified_sales AS (
    SELECT cs_sold_date_sk AS sold_date_sk,
           cs_item_sk AS item_sk,
           cs_net_profit AS profit,
           'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_item_sk,
           ss_net_profit,
           'store'
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_net_profit,
           'web'
    FROM web_sales
),
sales_agg AS (
    SELECT d.d_year,
           i.i_category,
           us.channel,
           SUM(us.profit) AS total_profit,
           COUNT(*) AS sales_count
    FROM unified_sales us
    JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
    JOIN item i ON us.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, i.i_category, us.channel
)
SELECT s.d_year,
       s.i_category,
       s.channel,
       s.total_profit,
       s.sales_count,
       RANK() OVER (PARTITION BY s.d_year ORDER BY s.total_profit DESC) AS profit_rank
FROM sales_agg s
WHERE s.total_profit > 0
ORDER BY s.total_profit DESC
LIMIT 200

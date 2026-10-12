WITH all_sales AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_net_paid AS net_paid,
           ss_net_profit AS net_profit
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_item_sk,
           cs_net_paid,
           cs_net_profit
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_net_paid,
           ws_net_profit
    FROM web_sales
),
agg_sales AS (
    SELECT d.d_year,
           i.i_category,
           SUM(s.net_paid) AS total_net_paid,
           SUM(s.net_profit) AS total_net_profit,
           COUNT(*) AS sales_count
    FROM all_sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, i.i_category
)
SELECT *
FROM (
    SELECT a.*,
           ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_net_paid DESC) AS rank_by_sales
    FROM agg_sales a
) t
WHERE t.rank_by_sales <= 10
ORDER BY t.d_year, t.rank_by_sales

WITH united_sales AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_quantity AS quantity,
           ss_net_paid AS net_paid,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_item_sk,
           cs_quantity,
           cs_net_paid,
           'catalog'
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_quantity,
           ws_net_paid,
           'web'
    FROM web_sales
),
aggregated_sales AS (
    SELECT d.d_year AS d_year,
           i.i_category AS i_category,
           s.channel,
           SUM(s.quantity) AS total_quantity,
           SUM(s.net_paid) AS total_net_paid
    FROM united_sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, s.channel
),
ranked_sales AS (
    SELECT d_year,
           i_category,
           channel,
           total_quantity,
           total_net_paid,
           ROW_NUMBER() OVER (PARTITION BY d_year, i_category ORDER BY total_net_paid DESC) AS rank_by_profit
    FROM aggregated_sales
)
SELECT d_year,
       i_category,
       channel,
       total_quantity,
       total_net_paid,
       rank_by_profit
FROM ranked_sales
WHERE rank_by_profit <= 3
ORDER BY d_year, i_category, rank_by_profit

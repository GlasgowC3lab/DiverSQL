WITH store_sales_filtered AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000 AND d.d_moy BETWEEN 1 AND 12
),
catalog_sales_filtered AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000 AND d.d_moy BETWEEN 1 AND 12
),
web_sales_filtered AS (
    SELECT ws.ws_sold_date_sk AS date_sk,
           ws.ws_item_sk AS item_sk,
           ws.ws_quantity AS quantity,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000 AND d.d_moy BETWEEN 1 AND 12
),
all_sales AS (
    SELECT date_sk, item_sk, quantity, net_paid, net_profit FROM store_sales_filtered
    UNION ALL
    SELECT date_sk, item_sk, quantity, net_paid, net_profit FROM catalog_sales_filtered
    UNION ALL
    SELECT date_sk, item_sk, quantity, net_paid, net_profit FROM web_sales_filtered
),
sales_with_date AS (
    SELECT a.*, d.d_year, d.d_moy,
           concat(cast(d.d_year AS varchar), '-', lpad(cast(d.d_moy AS varchar), 2, '0')) AS year_month
    FROM all_sales a
    JOIN date_dim d ON a.date_sk = d.d_date_sk
),
sales_enriched AS (
    SELECT s.*, i.i_category, i.i_class, i.i_brand
    FROM sales_with_date s
    JOIN item i ON s.item_sk = i.i_item_sk
)
SELECT year_month,
       i_category,
       i_class,
       i_brand,
       SUM(quantity) AS total_quantity,
       SUM(net_paid) AS total_revenue,
       SUM(net_profit) AS total_profit,
       AVG(net_profit) AS avg_profit_per_transaction,
       SUM(CASE WHEN net_profit > 0 THEN net_profit ELSE 0 END) AS profit_from_positive,
       SUM(CASE WHEN net_profit < 0 THEN net_profit ELSE 0 END) AS loss_from_negative
FROM sales_enriched
GROUP BY year_month, i_category, i_class, i_brand
ORDER BY total_revenue DESC
LIMIT 100

WITH unified_sales AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_ext_sales_price AS sales_amount,
           ss.ss_net_profit AS profit
    FROM store_sales ss
    UNION ALL
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_ext_sales_price AS sales_amount,
           cs.cs_net_profit AS profit
    FROM catalog_sales cs
    UNION ALL
    SELECT ws.ws_sold_date_sk AS date_sk,
           ws.ws_item_sk AS item_sk,
           ws.ws_ext_sales_price AS sales_amount,
           ws.ws_net_profit AS profit
    FROM web_sales ws
)
SELECT d.d_year,
       d.d_month_seq AS month,
       i.i_category,
       SUM(us.sales_amount) AS total_sales,
       SUM(us.profit) AS total_profit
FROM unified_sales us
JOIN date_dim d ON us.date_sk = d.d_date_sk
JOIN item i ON us.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 2001 AND 2002
GROUP BY d.d_year, d.d_month_seq, i.i_category
ORDER BY total_sales DESC
LIMIT 100

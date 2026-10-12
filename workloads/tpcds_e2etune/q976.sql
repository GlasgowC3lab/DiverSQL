WITH inv_filtered AS (
    SELECT inv_warehouse_sk,
           inv_item_sk,
           inv_date_sk,
           inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 500
      AND inv_date_sk BETWEEN 2450900 AND 2451060
),
sales_detail AS (
    SELECT ss_item_sk,
           ss_sold_date_sk,
           ss_store_sk,
           ss_ext_sales_price,
           ss_net_profit,
           ss_ext_discount_amt
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450900 AND 2451060
),
sales_agg AS (
    SELECT i.inv_warehouse_sk,
           w.web_country,
           SUM(s.ss_ext_sales_price)   AS total_sales,
           SUM(s.ss_net_profit)        AS total_profit,
           AVG(s.ss_ext_discount_amt) AS avg_discount,
           COUNT(*)                    AS sales_cnt
    FROM inv_filtered i
    JOIN sales_detail s
      ON i.inv_item_sk   = s.ss_item_sk
     AND i.inv_date_sk   = s.ss_sold_date_sk
    JOIN web_site w
      ON s.ss_store_sk = w.web_site_sk
    GROUP BY i.inv_warehouse_sk, w.web_country
    HAVING SUM(s.ss_ext_sales_price) > 5000
)
SELECT inv_warehouse_sk,
       web_country,
       total_sales,
       total_profit,
       avg_discount,
       sales_cnt,
       ROW_NUMBER() OVER (PARTITION BY inv_warehouse_sk ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY inv_warehouse_sk, profit_rank
LIMIT 20

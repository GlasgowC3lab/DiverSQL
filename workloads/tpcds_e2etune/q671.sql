WITH daily_item_sales AS (
    SELECT
        cs_item_sk,
        cs_sold_date_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_net_profit) AS avg_profit,
        SUM(cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs_order_number) AS orders_cnt
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450800 AND 2450830
      AND cs_ext_ship_cost > 500
    GROUP BY cs_item_sk, cs_sold_date_sk
    HAVING SUM(cs_ext_sales_price) > 10000
)
SELECT
    d1.cs_item_sk,
    d1.cs_sold_date_sk AS date_day1,
    d2.cs_sold_date_sk AS date_day2,
    d1.total_sales AS sales_day1,
    d2.total_sales AS sales_day2,
    d1.total_sales - d2.total_sales AS sales_diff,
    RANK() OVER (PARTITION BY d1.cs_item_sk ORDER BY d1.total_sales DESC) AS sales_rank
FROM daily_item_sales d1
JOIN daily_item_sales d2
    ON d1.cs_item_sk = d2.cs_item_sk
   AND d2.cs_sold_date_sk = d1.cs_sold_date_sk + 1
WHERE d1.orders_cnt > 5
ORDER BY sales_diff DESC
LIMIT 100

WITH item_sales AS (
    SELECT
        ss_item_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        SUM(ss_quantity) AS total_qty,
        AVG(ss_ext_discount_amt) AS avg_discount
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY ss_item_sk
)
SELECT
    i.i_brand,
    i.i_category,
    i.i_class,
    isales.total_sales,
    isales.total_profit,
    isales.total_qty,
    isales.avg_discount,
    RANK() OVER (PARTITION BY i.i_category ORDER BY isales.total_sales DESC) AS sales_rank_in_category
FROM item_sales isales
JOIN item i
    ON isales.ss_item_sk = i.i_item_sk
WHERE i.i_rec_end_date > DATE '2000-01-01'
  AND i.i_wholesale_cost > 1.00
  AND i.i_category_id IN (1, 3, 5)
  AND isales.total_sales > 10000
ORDER BY i.i_category, sales_rank_in_category
LIMIT 100

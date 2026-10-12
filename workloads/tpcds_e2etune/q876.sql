SELECT
    i.i_category,
    i.i_class,
    date_format(date_add('day', ss.ss_sold_date_sk, date '1970-01-01'), '%Y-%m') AS month,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(CASE WHEN ss.ss_ext_sales_price <> 0 THEN ss.ss_ext_discount_amt / ss.ss_ext_sales_price END) AS avg_discount_rate,
    COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
    ROW_NUMBER() OVER (
        PARTITION BY date_format(date_add('day', ss.ss_sold_date_sk, date '1970-01-01'), '%Y-%m')
        ORDER BY SUM(ss.ss_ext_sales_price) DESC
    ) AS category_rank
FROM store_sales ss
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
WHERE ss.ss_sold_date_sk BETWEEN 10957 AND 11322
  AND i.i_color IN ('Red', 'Blue', 'Green')
  AND i.i_brand = 'BrandX'
GROUP BY
    i.i_category,
    i.i_class,
    date_format(date_add('day', ss.ss_sold_date_sk, date '1970-01-01'), '%Y-%m')
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY month, total_sales DESC
LIMIT 20

SELECT
    i.i_item_id,
    i.i_product_name,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    (SELECT i2.i_current_price FROM item i2 WHERE i2.i_item_sk = ss.ss_item_sk) AS current_price
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
WHERE c.c_birth_year > 1927 AND i.i_brand_id = 1003002
GROUP BY i.i_item_id, i.i_product_name, ss.ss_item_sk, c.c_birth_month
HAVING c.c_birth_month = 3

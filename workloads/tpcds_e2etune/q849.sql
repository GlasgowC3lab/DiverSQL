SELECT
    s.s_store_name,
    i.i_category,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_quantity,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amount,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    AVG(wp_images.avg_images) AS avg_images_per_customer
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN (
    SELECT wp.wp_customer_sk, AVG(wp.wp_image_count) AS avg_images
    FROM web_page wp
    GROUP BY wp.wp_customer_sk
) wp_images ON wp_images.wp_customer_sk = c.c_customer_sk
WHERE s.s_state = 'CA'
  AND i.i_wholesale_cost > 20
  AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2453650
GROUP BY s.s_store_name, i.i_category
HAVING SUM(ss.ss_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 20

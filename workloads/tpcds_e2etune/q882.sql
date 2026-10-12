SELECT
    w.w_country,
    SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand,
    pc.preferred_customers_count,
    pc.distinct_web_pages
FROM
    inventory i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN LATERAL (
        SELECT
            COUNT(DISTINCT c.c_customer_sk) AS preferred_customers_count,
            COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages
        FROM web_page wp
        JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
        WHERE c.c_preferred_cust_flag = 'Y'
          AND c.c_birth_country = w.w_country
    ) AS pc ON TRUE
WHERE i.inv_quantity_on_hand > 0
GROUP BY w.w_country, pc.preferred_customers_count, pc.distinct_web_pages
HAVING SUM(i.inv_quantity_on_hand) > 1000
ORDER BY total_quantity_on_hand DESC
LIMIT 10

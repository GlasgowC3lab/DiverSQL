WITH monthly_sales AS (
    SELECT
        wp.wp_type AS page_type,
        date_trunc('month', date_add('day', ws.ws_sold_date_sk, DATE '1970-01-01')) AS month,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type IN ('home', 'product', 'search')
      AND ws.ws_quantity > 1
      AND ws.ws_sold_date_sk BETWEEN 20000 AND 21000
    GROUP BY wp.wp_type, date_trunc('month', date_add('day', ws.ws_sold_date_sk, DATE '1970-01-01'))
    HAVING SUM(ws.ws_ext_sales_price) > 50000
)
SELECT
    page_type,
    month,
    total_sales,
    avg_discount,
    distinct_orders,
    total_quantity,
    ROW_NUMBER() OVER (PARTITION BY page_type ORDER BY total_sales DESC) AS sales_rank
FROM monthly_sales
ORDER BY total_sales DESC
LIMIT 100

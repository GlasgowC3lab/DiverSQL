WITH sales_agg AS (
    SELECT
        p.p_channel_email AS promo_channel,
        c.c_birth_country AS birth_country,
        wp.wp_type AS page_type,
        ws.ws_sold_date_sk AS sold_date_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(COALESCE(wr.wr_refunded_cash, 0)) AS total_refunds,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450915
        AND c.c_preferred_cust_flag = 'Y'
        AND p.p_channel_email IS NOT NULL
    GROUP BY p.p_channel_email, c.c_birth_country, wp.wp_type, ws.ws_sold_date_sk
    HAVING SUM(ws.ws_net_paid) > 10000
)
SELECT
    promo_channel,
    birth_country,
    page_type,
    sold_date_sk,
    total_sales,
    total_refunds,
    total_sales - total_refunds AS net_sales,
    avg_discount,
    distinct_customers,
    RANK() OVER (PARTITION BY promo_channel ORDER BY (total_sales - total_refunds) DESC) AS sales_rank
FROM sales_agg
ORDER BY net_sales DESC
LIMIT 100

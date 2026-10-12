WITH sales_agg AS (
    SELECT
        hd.hd_demo_sk,
        wp.wp_web_page_sk,
        wp.wp_type,
        COUNT(ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_unit_price,
        MIN(ws.ws_sales_price) AS min_price,
        MAX(ws.ws_sales_price) AS max_price,
        SUM(ws.ws_quantity) AS total_quantity,
        MIN(ws.ws_order_number) AS min_order_number,
        MAX(ws.ws_order_number) AS max_order_number
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_sales_price >= 10
      AND ws.ws_sales_price <= 200
      AND ws.ws_quantity > 0
      AND ws.ws_ext_sales_price > 0
      AND wp.wp_max_ad_count BETWEEN 0 AND 4
      AND wp.wp_rec_start_date >= DATE '1999-01-01'
      AND wp.wp_rec_start_date <= DATE '2001-12-31'
      AND hd.hd_dep_count IN (1, 4, 7, 8, 9)
    GROUP BY hd.hd_demo_sk, wp.wp_web_page_sk, wp.wp_type
)
SELECT
    sa.hd_demo_sk,
    sa.wp_type,
    sa.order_cnt,
    sa.total_sales,
    sa.avg_unit_price,
    sa.total_quantity
FROM sales_agg sa
WHERE sa.min_order_number NOT IN (
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_sales_price > 250
)
ORDER BY sa.total_sales DESC
LIMIT 100

WITH page_sales AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_type,
        ws.ws_web_site_sk,
        SUM(ws.ws_net_profit) AS profit,
        SUM(ws.ws_ext_sales_price) AS sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_quantity) AS total_qty
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_autogen_flag = 'N'
      AND wp.wp_image_count > 2
      AND wp.wp_link_count BETWEEN 5 AND 15
      AND ws.ws_net_profit > 0
      AND ws.ws_sold_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY wp.wp_web_page_sk, wp.wp_type, ws.ws_web_site_sk
    HAVING SUM(ws.ws_net_profit) > 500
)
SELECT
    wsit.web_site_id,
    wsit.web_name,
    ps.wp_type,
    ps.profit,
    ps.sales,
    ps.avg_discount,
    ps.order_cnt,
    ps.total_qty,
    RANK() OVER (PARTITION BY wsit.web_site_id ORDER BY ps.profit DESC) AS profit_rank
FROM page_sales ps
JOIN web_site wsit ON ps.ws_web_site_sk = wsit.web_site_sk
WHERE ps.sales > 1000
ORDER BY wsit.web_site_id, profit_rank
LIMIT 100

WITH sales_data AS (
    SELECT
        ca.ca_state,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        wp.wp_url,
        wp.wp_type,
        regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
        CONCAT(SUBSTR(wp.wp_type, 1, 3), '_', ca.ca_state) AS type_state_key
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND wp.wp_url LIKE '%example.com%'
      AND regexp_like(wp.wp_url, '^https?://[^/]*example\\.com')
)
SELECT
    ca_state,
    domain,
    type_state_key,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    CASE WHEN SUM(ws_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_status
FROM sales_data
GROUP BY ca_state, domain, type_state_key
ORDER BY total_sales DESC
LIMIT 100

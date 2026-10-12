WITH brand_page_profit AS (
    SELECT
        i.i_brand,
        wp.wp_type,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_web_page_sk) AS distinct_pages,
        COUNT(*) AS transaction_count
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE i.i_wholesale_cost > 5.00
      AND ws.ws_quantity > 0
      AND wp.wp_type IS NOT NULL
    GROUP BY i.i_brand, wp.wp_type
)
SELECT
    i_brand,
    wp_type,
    total_net_profit,
    total_sales,
    avg_discount,
    distinct_pages,
    transaction_count,
    RANK() OVER (PARTITION BY i_brand ORDER BY total_net_profit DESC) AS profit_rank
FROM brand_page_profit
WHERE total_net_profit > 5000
ORDER BY i_brand, profit_rank
LIMIT 100

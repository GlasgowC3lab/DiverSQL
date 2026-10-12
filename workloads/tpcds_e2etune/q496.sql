WITH sales_agg AS (
    SELECT
        d_sold.d_year,
        d_sold.d_quarter_name,
        ws.ws_web_site_sk,
        wsite.web_name,
        wp.wp_type,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_sold
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d_sold.d_year BETWEEN 1900 AND 1904
      AND wsite.web_state = 'CA'
      AND d_ship.d_weekend = 'N'
      AND wp.wp_type IN ('product', 'category')
    GROUP BY d_sold.d_year, d_sold.d_quarter_name, ws.ws_web_site_sk, wsite.web_name, wp.wp_type
    HAVING SUM(ws.ws_net_profit) > 1000
)
SELECT
    d_year,
    d_quarter_name,
    ws_web_site_sk,
    web_name,
    wp_type,
    total_net_profit,
    total_sales,
    avg_discount,
    distinct_items_sold,
    RANK() OVER (PARTITION BY d_year, d_quarter_name ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100

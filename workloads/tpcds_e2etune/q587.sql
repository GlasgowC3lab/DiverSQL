WITH city_page_ship AS (
    SELECT
        ca.ca_city AS billing_city,
        ca_ship.ca_city AS shipping_city,
        wp.wp_type AS page_type,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ca.ca_country = 'United States'
      AND wp.wp_type = 'product'
      AND ws.ws_sold_date_sk BETWEEN 2458849 AND 2459214
    GROUP BY ca.ca_city, ca_ship.ca_city, wp.wp_type
)
SELECT
    billing_city,
    shipping_city,
    page_type,
    total_net_profit,
    avg_discount,
    total_quantity,
    distinct_customers,
    CASE WHEN billing_city = shipping_city THEN 'Same City' ELSE 'Different City' END AS city_match,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM city_page_ship
WHERE total_net_profit > 1000
ORDER BY profit_rank
LIMIT 10

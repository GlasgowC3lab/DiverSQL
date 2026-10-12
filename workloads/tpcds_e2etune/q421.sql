WITH sales_agg AS (
    SELECT
        ca.ca_state AS bill_state,
        ca2.ca_state AS ship_state,
        wp.wp_type AS page_type,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_address ca2 ON ws.ws_ship_addr_sk = ca2.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ca.ca_country = 'United States'
      AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2451910
      AND wp.wp_type IS NOT NULL
    GROUP BY ca.ca_state, ca2.ca_state, wp.wp_type
    HAVING COUNT(DISTINCT ws.ws_order_number) >= 5
)
SELECT
    bill_state,
    ship_state,
    page_type,
    order_cnt,
    total_profit,
    avg_discount,
    RANK() OVER (PARTITION BY page_type ORDER BY total_profit DESC) AS profit_rank_state
FROM sales_agg
ORDER BY page_type, profit_rank_state
LIMIT 100

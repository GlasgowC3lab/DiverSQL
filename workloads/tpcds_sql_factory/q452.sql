WITH sales_by_address AS (
    SELECT
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ca_bill.ca_state AS bill_state,
        ca_bill.ca_city AS bill_city,
        ca_ship.ca_state AS ship_state,
        ca_ship.ca_city AS ship_city,
        i.i_brand,
        ws.ws_sold_date_sk
    FROM web_sales ws
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
),
aggregated_sales AS (
    SELECT
        bill_state,
        bill_city,
        i_brand,
        ship_state,
        COUNT(*) AS orders,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_ext_discount_amt) AS avg_discount,
        SUM(ws_net_profit) AS total_profit
    FROM sales_by_address
    GROUP BY bill_state, bill_city, i_brand, ship_state
    HAVING COUNT(*) >= 5
)
SELECT
    bill_state,
    bill_city,
    i_brand,
    orders,
    total_sales,
    avg_discount,
    total_profit,
    CASE
        WHEN bill_state = ship_state THEN 'Same_State'
        ELSE 'Different_State'
    END AS ship_bill_state_match,
    PERCENT_RANK() OVER (PARTITION BY bill_state ORDER BY total_sales DESC) AS state_sales_percentile
FROM aggregated_sales
ORDER BY total_sales DESC
LIMIT 100

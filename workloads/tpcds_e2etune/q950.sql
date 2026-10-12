WITH billing_addr AS (
    SELECT ca_address_sk, ca_state, ca_country
    FROM customer_address
),
shipping_addr AS (
    SELECT ca_address_sk, ca_state AS ship_state, ca_country AS ship_country
    FROM customer_address
),
sales_agg AS (
    SELECT
        ws_bill_addr_sk,
        ws_ship_addr_sk,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_ext_discount_amt) AS total_discount,
        AVG(ws_sales_price) AS avg_sales_price,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450845 AND 2451088
    GROUP BY ws_bill_addr_sk, ws_ship_addr_sk
)
SELECT
    b.ca_state AS billing_state,
    s.ship_state,
    sa.total_net_paid,
    sa.total_discount,
    sa.avg_sales_price,
    sa.total_profit,
    sa.order_count,
    ROW_NUMBER() OVER (PARTITION BY b.ca_state ORDER BY sa.total_profit DESC) AS profit_rank,
    (SELECT COUNT(*) FROM catalog_page WHERE cp_type = 'quarterly') AS quarterly_page_count
FROM sales_agg sa
JOIN billing_addr b ON sa.ws_bill_addr_sk = b.ca_address_sk
JOIN shipping_addr s ON sa.ws_ship_addr_sk = s.ca_address_sk
WHERE b.ca_country = 'United States' AND s.ship_country = 'United States'
  AND sa.total_profit > 1000
ORDER BY sa.total_profit DESC
LIMIT 100

WITH site_item_profit AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        i.i_product_name,
        i.i_brand,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_ext_list_price,
        ws.ws_ext_wholesale_cost,
        ws.ws_sold_date_sk,
        ca.ca_state AS bill_state,
        ca.ca_city AS bill_city
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
),
aggregated AS (
    SELECT
        s.web_name,
        p.i_product_name,
        p.i_brand,
        p.bill_state,
        SUM(p.ws_net_profit) AS total_net_profit,
        SUM(p.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT p.ws_order_number) AS orders,
        CASE
            WHEN SUM(p.ws_net_profit) > 100000 THEN 'High'
            WHEN SUM(p.ws_net_profit) > 50000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM site_item_profit p
    JOIN web_site s ON p.ws_web_site_sk = s.web_site_sk
    GROUP BY s.web_name, p.i_product_name, p.i_brand, p.bill_state
    HAVING SUM(p.ws_ext_sales_price) > 10000
)
SELECT
    web_name,
    i_product_name,
    i_brand,
    bill_state,
    total_net_profit,
    total_sales,
    orders,
    profit_category,
    RANK() OVER (PARTITION BY web_name ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY web_name, profit_rank
LIMIT 50

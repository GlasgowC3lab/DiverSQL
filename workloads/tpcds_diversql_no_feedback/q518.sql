WITH filtered_items AS (
    SELECT i_item_sk, i_item_desc
    FROM item
    WHERE regexp_like(i_item_desc, '(?i)blue')
)
SELECT
    ws.ws_web_site_sk,
    ws_site.web_name,
    ws_site.web_company_name,
    SUBSTRING(ws_site.web_company_name FROM 1 FOR 10) AS company_prefix,
    t.t_meal_time,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
    CONCAT(ws_addr.ca_city, ', ', ws_addr.ca_state) AS address
FROM
    web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN customer_address ws_addr ON ws.ws_bill_addr_sk = ws_addr.ca_address_sk
    JOIN filtered_items fi ON ws.ws_item_sk = fi.i_item_sk
WHERE
    ws_site.web_gmt_offset = -5.00
    AND ws_site.web_company_name LIKE '%a%'
    AND regexp_like(ws_site.web_name, '^Web.*')
    AND ws_addr.ca_city LIKE '%York%'
    AND ws.ws_item_sk IN (
        SELECT i_item_sk
        FROM item
        WHERE regexp_like(i_item_desc, '(?i)small')
    )
GROUP BY
    ws.ws_web_site_sk,
    ws_site.web_name,
    ws_site.web_company_name,
    SUBSTRING(ws_site.web_company_name FROM 1 FOR 10),
    t.t_meal_time,
    CONCAT(ws_addr.ca_city, ', ', ws_addr.ca_state)
ORDER BY
    total_net_paid DESC
LIMIT 100

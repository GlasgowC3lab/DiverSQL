WITH inv_agg AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk
)
SELECT
    ws.ws_order_number,
    i.i_item_id,
    i.i_product_name,
    c.c_customer_id,
    ca.ca_city,
    ws.ws_ext_sales_price,
    ws.ws_net_paid,
    cr.cr_return_amount,
    inv_agg.total_quantity_on_hand,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
    ) AS total_return_amount_for_item,
    ROW_NUMBER() OVER (ORDER BY ws.ws_ext_sales_price DESC) AS rn_global,
    RANK() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_ext_sales_price DESC) AS site_sales_rank
FROM web_sales ws
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN inv_agg
    ON inv_agg.inv_item_sk = i.i_item_sk
WHERE ca.ca_street_type IN ('Pkwy', 'ST')
  AND ca.ca_country = 'United States'
  AND ws.ws_ext_sales_price > 1000
  AND i.i_current_price BETWEEN 10 AND 100
ORDER BY ws.ws_ext_sales_price DESC
LIMIT 100

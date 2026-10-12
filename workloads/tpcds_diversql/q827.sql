WITH avg_net AS (
    SELECT avg(cs.cs_net_paid_inc_ship_tax) AS avg_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
)
SELECT sale_date,
       order_number,
       net_paid,
       payment_category,
       channel
FROM (
    SELECT
        d.d_date AS sale_date,
        cs.cs_order_number AS order_number,
        cs.cs_net_paid_inc_ship_tax AS net_paid,
        CASE WHEN cs.cs_net_paid_inc_ship_tax > (SELECT avg_paid FROM avg_net)
            THEN 'High' ELSE 'Low' END AS payment_category,
        'Catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
      AND EXISTS (
            SELECT 1
            FROM inventory i
            JOIN date_dim d2 ON i.inv_date_sk = d2.d_date_sk
            WHERE i.inv_item_sk = cs.cs_item_sk
              AND i.inv_quantity_on_hand > 0
              AND d2.d_date = d.d_date
          )
    UNION ALL
    SELECT
        d.d_date AS sale_date,
        ws.ws_order_number AS order_number,
        ws.ws_net_paid_inc_ship_tax AS net_paid,
        CASE WHEN ws.ws_net_paid_inc_ship_tax > (SELECT avg_paid FROM avg_net)
            THEN 'High' ELSE 'Low' END AS payment_category,
        'Web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
      AND EXISTS (
            SELECT 1
            FROM inventory i
            JOIN date_dim d2 ON i.inv_date_sk = d2.d_date_sk
            WHERE i.inv_item_sk = ws.ws_item_sk
              AND i.inv_quantity_on_hand > 0
              AND d2.d_date = d.d_date
          )
) AS combined
ORDER BY sale_date DESC, net_paid DESC
LIMIT 100

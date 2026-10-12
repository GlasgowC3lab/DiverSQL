WITH catalog_sales_no_return AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_sold_date_sk AS sold_date_sk,
        d.d_date AS sold_date,
        cs.cs_item_sk AS item_sk,
        cs.cs_sales_price AS sales_price,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_sold_date_sk ORDER BY cs.cs_net_paid DESC) AS rn
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_order_number = cs.cs_order_number
      )
),
web_sales_no_inventory AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_sold_date_sk AS sold_date_sk,
        d.d_date AS sold_date,
        ws.ws_item_sk AS item_sk,
        ws.ws_sales_price AS sales_price,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY ws.ws_net_paid DESC) AS rn
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND NOT EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_date_sk = ws.ws_sold_date_sk
            AND inv.inv_item_sk = ws.ws_item_sk
      )
)
SELECT
    order_number,
    sold_date,
    item_sk,
    sales_price,
    quantity,
    net_paid,
    rn
FROM catalog_sales_no_return
UNION ALL
SELECT
    order_number,
    sold_date,
    item_sk,
    sales_price,
    quantity,
    net_paid,
    rn
FROM web_sales_no_inventory
ORDER BY sold_date DESC, rn
LIMIT 100

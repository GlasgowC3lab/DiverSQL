WITH store_part AS (
    SELECT
        d.d_date AS sale_date,
        'store' AS channel,
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        (
            SELECT SUM(cs2.cs_quantity)
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = cs.cs_item_sk
        ) AS total_item_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_item_sk IN (
            SELECT inv_item_sk
            FROM inventory
            WHERE inv_quantity_on_hand > 500
        )
      AND d.d_year = 2001
      AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_promo_sk = cs.cs_promo_sk
              AND p2.p_discount_active = 'Y'
        )
    GROUP BY d.d_date, cs.cs_item_sk
),
web_part AS (
    SELECT
        d.d_date AS sale_date,
        'web' AS channel,
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        (
            SELECT SUM(ws2.ws_quantity)
            FROM web_sales ws2
            WHERE ws2.ws_item_sk = ws.ws_item_sk
        ) AS total_item_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_item_sk IN (
            SELECT inv_item_sk
            FROM inventory
            WHERE inv_quantity_on_hand > 500
        )
      AND d.d_year = 2001
      AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_promo_sk = ws.ws_promo_sk
              AND p2.p_discount_active = 'Y'
        )
    GROUP BY d.d_date, ws.ws_item_sk
)
SELECT
    sale_date,
    channel,
    item_sk,
    total_sales,
    total_quantity,
    total_item_quantity
FROM store_part
UNION ALL
SELECT
    sale_date,
    channel,
    item_sk,
    total_sales,
    total_quantity,
    total_item_quantity
FROM web_part
ORDER BY sale_date DESC, total_sales DESC
LIMIT 100

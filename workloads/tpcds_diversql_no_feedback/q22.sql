WITH cs AS (
    SELECT
        d.d_date AS sale_date,
        cs.cs_item_sk AS item_sk,
        cs.cs_sales_price AS sales_price,
        cs.cs_net_paid AS net_paid,
        p.p_promo_name AS promo_name,
        sm.sm_type AS ship_mode_type
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 1998
      AND p.p_promo_name LIKE '%Discount%'
),
ws AS (
    SELECT
        d.d_date AS sale_date,
        ws.ws_item_sk AS item_sk,
        ws.ws_sales_price AS sales_price,
        ws.ws_net_paid AS net_paid,
        p.p_promo_name AS promo_name,
        sm.sm_type AS ship_mode_type
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 1998
      AND p.p_promo_name LIKE '%Discount%'
),
combined AS (
    SELECT * FROM cs
    UNION ALL
    SELECT * FROM ws
)
SELECT
    sale_date,
    item_sk,
    sales_price,
    net_paid,
    promo_name,
    ship_mode_type,
    LAG(sales_price) OVER (PARTITION BY item_sk ORDER BY sale_date) AS prev_sales_price,
    SUM(net_paid) OVER (PARTITION BY item_sk ORDER BY sale_date ROWS UNBOUNDED PRECEDING) AS running_net_paid
FROM combined
ORDER BY item_sk, sale_date
LIMIT 100

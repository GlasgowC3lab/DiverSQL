WITH catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_moy AS month,
        i.i_category,
        'catalog' AS source,
        SUM(cs.cs_net_paid) AS sales_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_dmail = 'Y'
      AND d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, i.i_category
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_moy AS month,
        i.i_category,
        'web' AS source,
        SUM(ws.ws_net_paid) AS sales_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_dmail = 'Y'
      AND d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, i.i_category
),
combined_sales AS (
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
)
SELECT
    d_year,
    month,
    i_category,
    source,
    SUM(sales_amount) AS total_sales,
    CASE WHEN SUM(sales_amount) > 10000 THEN 'High' ELSE 'Low' END AS sales_level,
    (
        SELECT SUM(inv.inv_quantity_on_hand)
        FROM inventory inv
        JOIN item i2 ON inv.inv_item_sk = i2.i_item_sk
        WHERE i2.i_category = combined_sales.i_category
    ) AS total_inventory_quantity
FROM combined_sales
GROUP BY ROLLUP (d_year, month, i_category, source)
ORDER BY d_year, month, i_category, source
LIMIT 100

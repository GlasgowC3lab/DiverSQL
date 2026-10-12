WITH item_sales AS (
    SELECT
        d.d_quarter_name AS quarter,
        cs.cs_item_sk AS item_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_ship_cost) / NULLIF(SUM(cs.cs_quantity), 0) AS avg_ship_cost_per_unit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cd.cd_gender) AS distinct_shipping_genders,
        sm.sm_type AS ship_mode_type
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    GROUP BY d.d_quarter_name, cs.cs_item_sk, sm.sm_type
),
ranked_items AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY quarter ORDER BY total_sales DESC) AS rn,
        MAX(total_sales) OVER (PARTITION BY quarter) AS max_sales_in_quarter,
        CASE WHEN total_profit < 0 THEN 'Loss' ELSE 'Profit' END AS profit_status,
        CASE
            WHEN total_profit / NULLIF(total_sales, 0) >= 0.2 THEN 'High Margin'
            WHEN total_profit / NULLIF(total_sales, 0) >= 0.1 THEN 'Medium Margin'
            ELSE 'Low Margin'
        END AS margin_category
    FROM item_sales
)
SELECT
    quarter,
    item_id,
    total_sales,
    total_profit,
    profit_status,
    margin_category,
    avg_ship_cost_per_unit,
    total_quantity,
    distinct_shipping_genders,
    ship_mode_type,
    max_sales_in_quarter,
    total_sales * 100.0 / max_sales_in_quarter AS sales_share_pct
FROM ranked_items
WHERE rn <= 5
ORDER BY quarter, rn

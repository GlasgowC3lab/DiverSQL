WITH sales_monthly AS (
    SELECT
        ws.ws_web_site_sk,
        i.i_brand,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_sales_price,
        CAST(FLOOR(ws.ws_sold_date_sk / 100) AS INTEGER) AS year_month
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
monthly_brand_agg AS (
    SELECT
        s.web_name,
        sm.year_month,
        sm.i_brand,
        SUM(sm.ws_ext_sales_price) AS monthly_sales,
        SUM(sm.ws_quantity) AS monthly_units,
        SUM(sm.ws_net_profit) AS monthly_profit,
        AVG(sm.ws_sales_price) AS avg_sales_price
    FROM sales_monthly sm
    JOIN web_site s ON sm.ws_web_site_sk = s.web_site_sk
    GROUP BY s.web_name, sm.year_month, sm.i_brand
    HAVING SUM(sm.ws_ext_sales_price) > 5000
),
ranked_brand AS (
    SELECT
        *,
        DENSE_RANK() OVER (PARTITION BY web_name, year_month ORDER BY monthly_sales DESC) AS brand_rank
    FROM monthly_brand_agg
)
SELECT
    web_name,
    year_month,
    i_brand,
    monthly_sales,
    monthly_units,
    monthly_profit,
    CASE
        WHEN avg_sales_price >= 100 THEN 'Premium'
        WHEN avg_sales_price >= 50 THEN 'Midrange'
        ELSE 'Budget'
    END AS price_tier,
    brand_rank
FROM ranked_brand
WHERE brand_rank = 1
ORDER BY web_name, year_month

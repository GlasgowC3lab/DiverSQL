WITH sales_address AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_ext_sales_price,
        ws.ws_sold_date_sk,
        ca_bill.ca_state AS bill_state,
        ca_bill.ca_city AS bill_city,
        ca_ship.ca_state AS ship_state,
        ca_ship.ca_city AS ship_city,
        CAST(FLOOR(ws.ws_sold_date_sk / 100) AS INTEGER) AS year_month
    FROM web_sales ws
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
),
monthly_site_sales AS (
    SELECT
        s.web_name,
        sa.year_month,
        SUM(sa.ws_ext_sales_price) AS month_sales,
        COUNT(*) AS orders,
        SUM(CASE WHEN sa.bill_state = sa.ship_state THEN 1 ELSE 0 END) AS same_state_orders,
        SUM(CASE WHEN sa.bill_city = sa.ship_city THEN 1 ELSE 0 END) AS same_city_orders
    FROM sales_address sa
    JOIN web_site s ON sa.ws_web_site_sk = s.web_site_sk
    GROUP BY s.web_name, sa.year_month
)
SELECT
    web_name,
    year_month,
    month_sales,
    orders,
    same_state_orders,
    same_city_orders,
    ROUND(100.0 * same_state_orders / orders, 2) AS pct_same_state,
    ROUND(100.0 * same_city_orders / orders, 2) AS pct_same_city,
    SUM(month_sales) OVER (PARTITION BY web_name ORDER BY year_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
    LAG(month_sales) OVER (PARTITION BY web_name ORDER BY year_month) AS prior_month_sales,
    CASE
        WHEN month_sales > COALESCE(LAG(month_sales) OVER (PARTITION BY web_name ORDER BY year_month), 0) THEN 'Increase'
        WHEN month_sales < COALESCE(LAG(month_sales) OVER (PARTITION BY web_name ORDER BY year_month), 0) THEN 'Decrease'
        ELSE 'Flat'
    END AS sales_trend
FROM monthly_site_sales
WHERE year_month >= 202201
ORDER BY web_name, year_month

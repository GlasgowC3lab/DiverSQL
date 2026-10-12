WITH sales_data AS (
    -- Sales based on the order (sold) date, filtered to fiscal year 1916 and ship mode 5
    SELECT
        d.d_fy_year AS fiscal_year,
        d.d_moy AS month_of_year,
        ws.ws_ext_sales_price AS sales_amount,
        i.inv_quantity_on_hand AS qty_on_hand
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 1916
      AND ws.ws_ship_mode_sk = 5

    UNION ALL

    -- Sales based on the ship date, filtered to fiscal year 1916 and ship mode 7
    SELECT
        d.d_fy_year AS fiscal_year,
        d.d_moy AS month_of_year,
        ws.ws_ext_sales_price AS sales_amount,
        i.inv_quantity_on_hand AS qty_on_hand
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 1916
      AND ws.ws_ship_mode_sk = 7
)
SELECT
    fiscal_year,
    month_of_year,
    SUM(sales_amount) AS total_sales,
    SUM(qty_on_hand) AS total_qty_on_hand
FROM sales_data
GROUP BY ROLLUP (fiscal_year, month_of_year)
ORDER BY fiscal_year, month_of_year
LIMIT 100

WITH profit_by_type_income AS (
    SELECT
        wp.wp_type,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY wp.wp_type, ib.ib_lower_bound, ib.ib_upper_bound
),
ranked_profit AS (
    SELECT
        wp_type,
        ib_lower_bound,
        ib_upper_bound,
        distinct_pages,
        total_profit,
        avg_sales_price,
        total_sales,
        total_quantity,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
        DENSE_RANK() OVER (ORDER BY avg_sales_price DESC) AS avg_price_dense_rank,
        SUM(total_profit) OVER (ORDER BY ib_lower_bound ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit_by_income
    FROM profit_by_type_income
)
SELECT
    wp_type,
    ib_lower_bound,
    ib_upper_bound,
    distinct_pages,
    total_profit,
    avg_sales_price,
    total_sales,
    total_quantity,
    profit_rank,
    avg_price_dense_rank,
    cum_profit_by_income,
    CASE
        WHEN total_profit > 200000 THEN 'Platinum'
        WHEN total_profit > 100000 THEN 'Gold'
        WHEN total_profit > 50000 THEN 'Silver'
        ELSE 'Bronze'
    END AS profit_tier
FROM ranked_profit
WHERE total_quantity > 100
ORDER BY profit_rank
LIMIT 30

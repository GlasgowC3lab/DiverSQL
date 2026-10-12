WITH page_perf AS (
    SELECT
        wp.wp_web_page_id AS wp_id,
        wp.wp_type,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_coupon_amt) AS avg_coupon
    FROM web_sales ws
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY wp.wp_web_page_id, wp.wp_type, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    wp_id,
    wp_type,
    ib_lower_bound,
    ib_upper_bound,
    total_sales,
    total_profit,
    avg_coupon,
    CASE
        WHEN total_profit > 100000 THEN 'HIGH'
        WHEN total_profit > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
    DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_dense_rank
FROM page_perf
WHERE total_sales > 10000
ORDER BY profit_rank
LIMIT 20

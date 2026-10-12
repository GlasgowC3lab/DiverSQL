WITH daily_coupon AS (
    SELECT
        ws.ws_sold_date_sk,
        wp.wp_type,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ws.ws_coupon_amt) AS total_coupon,
        COUNT(*) AS txn_count,
        AVG(ws.ws_coupon_amt) AS avg_coupon,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ws.ws_sold_date_sk, wp.wp_type, ib.ib_lower_bound, ib.ib_upper_bound
),
coupon_rank AS (
    SELECT
        ws_sold_date_sk,
        wp_type,
        ib_lower_bound,
        ib_upper_bound,
        total_coupon,
        txn_count,
        avg_coupon,
        total_sales,
        DENSE_RANK() OVER (PARTITION BY wp_type ORDER BY total_coupon DESC) AS coupon_dense_rank,
        SUM(total_coupon) OVER (PARTITION BY wp_type ORDER BY ws_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_coupon
    FROM daily_coupon
)
SELECT
    ws_sold_date_sk,
    wp_type,
    ib_lower_bound,
    ib_upper_bound,
    total_coupon,
    txn_count,
    avg_coupon,
    total_sales,
    coupon_dense_rank,
    cumulative_coupon,
    CASE
        WHEN cumulative_coupon > 50000 THEN 'Very High'
        WHEN cumulative_coupon > 20000 THEN 'High'
        ELSE 'Normal'
    END AS cumulative_coupon_category
FROM coupon_rank
WHERE total_sales > 1000
ORDER BY wp_type, coupon_dense_rank
LIMIT 50

WITH sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        w.w_warehouse_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY cs.cs_bill_customer_sk, w.w_warehouse_id
)
SELECT
    sa.customer_sk,
    sa.w_warehouse_id,
    sa.total_sales,
    sa.total_profit,
    sa.sales_cnt,
    CASE WHEN sa.total_sales > 20000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    wp.wp_max_ad_count
FROM sales_agg sa
JOIN customer c ON sa.customer_sk = c.c_customer_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
WHERE
    sa.total_sales > 5000
    AND sa.total_profit > 1000
    AND ib.ib_upper_bound <= 200000
    AND wp.wp_max_ad_count >= 1
    AND NOT EXISTS (
        SELECT 1 FROM store_returns sr
        WHERE sr.sr_customer_sk = sa.customer_sk
          AND sr.sr_return_amt > 100
    )
ORDER BY sa.total_sales DESC
LIMIT 100

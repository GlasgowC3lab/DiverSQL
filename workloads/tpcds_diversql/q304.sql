-- Trino SQL query joining all selected tables, applying filters, sampling, full outer join, and aggregation
WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
joined_catalog AS (
    SELECT
        cs.cs_order_number AS cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_coupon_amt,
        cs.cs_net_profit,
        cp.cp_department,
        sm.sm_type,
        hd.hd_income_band_sk,
        cc.cc_name
    FROM sampled_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_coupon_amt > 2000
      AND cs.cs_ship_date_sk BETWEEN 2450840 AND 2450900
      AND cp.cp_catalog_page_id = 'AAAAAAAACAAAAAAA'
      AND sm.sm_contract = 'GNJr3g5i7oorKqtX'
      AND hd.hd_income_band_sk = 5
),
catalog_ret AS (
    SELECT
        cr.cr_order_number AS cr_order_number,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cp.cp_department AS cr_department,
        sm.sm_type AS cr_ship_type,
        hd.hd_income_band_sk AS cr_income_band
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_amount > 500
),
web_ret AS (
    SELECT
        wr.wr_order_number AS wr_order_number,
        wr.wr_return_amt,
        wr.wr_net_loss,
        ws.ws_quantity,
        sm.sm_type AS ws_ship_type,
        hd.hd_income_band_sk AS ws_income_band
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_return_amt > 300
),
full_returns AS (
    SELECT *
    FROM catalog_ret
    FULL OUTER JOIN web_ret
        ON catalog_ret.cr_order_number = web_ret.wr_order_number
)
SELECT
    j.cp_department,
    j.sm_type,
    CASE WHEN j.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
    COUNT(DISTINCT j.cs_order_number) AS num_orders,
    SUM(j.cs_ext_sales_price) AS total_sales,
    AVG(j.cs_coupon_amt) AS avg_coupon,
    SUM(COALESCE(fr.cr_return_amount, 0)) AS total_catalog_returns,
    SUM(COALESCE(fr.wr_return_amt, 0)) AS total_web_returns,
    SUM(COALESCE(fr.cr_net_loss, 0) + COALESCE(fr.wr_net_loss, 0)) AS total_return_loss
FROM joined_catalog j
LEFT JOIN full_returns fr
    ON j.cs_order_number = fr.cr_order_number
GROUP BY
    j.cp_department,
    j.sm_type,
    CASE WHEN j.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END
ORDER BY total_sales DESC
LIMIT 100

WITH cr_hd AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_store_credit,
        cr.cr_refunded_cash,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_store_credit > 0
      AND cr.cr_refunded_cash < 500
),
ws_hd AS (
    SELECT
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_ext_wholesale_cost,
        ws.ws_web_page_sk,
        ws.ws_order_number,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_ext_wholesale_cost > 1000
      AND hd.hd_income_band_sk IN (8, 14)
      AND hd.hd_buy_potential = '1001-5000'
),
full_join AS (
    SELECT
        cr_hd.hd_income_band_sk,
        cr_hd.hd_buy_potential,
        cr_hd.hd_dep_count,
        cr_hd.hd_vehicle_count,
        cr_hd.cr_return_amount,
        cr_hd.cr_store_credit,
        cr_hd.cr_refunded_cash,
        ws_hd.ws_ext_sales_price,
        ws_hd.ws_net_profit,
        ws_hd.ws_ext_wholesale_cost,
        ws_hd.ws_web_page_sk,
        ws_hd.ws_order_number,
        COALESCE(cr_hd.hd_demo_sk, ws_hd.hd_demo_sk) AS hd_demo_sk
    FROM cr_hd
    FULL OUTER JOIN ws_hd
        ON cr_hd.hd_demo_sk = ws_hd.hd_demo_sk
),
agg AS (
    SELECT
        fj.hd_income_band_sk,
        fj.hd_buy_potential,
        fj.hd_dep_count,
        fj.hd_vehicle_count,
        wp.wp_type,
        SUM(fj.cr_return_amount) AS total_return_amount,
        SUM(fj.ws_ext_sales_price) AS total_sales_price,
        AVG(fj.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT fj.ws_order_number) AS distinct_orders,
        MIN(fj.ws_ext_wholesale_cost) AS min_wholesale_cost,
        MAX(fj.ws_ext_wholesale_cost) AS max_wholesale_cost
    FROM full_join fj
    LEFT JOIN web_page wp
        ON fj.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY ROLLUP (fj.hd_income_band_sk, fj.hd_buy_potential, fj.hd_dep_count, fj.hd_vehicle_count, wp.wp_type)
)
SELECT
    hd_income_band_sk,
    hd_buy_potential,
    hd_dep_count,
    hd_vehicle_count,
    wp_type,
    total_return_amount,
    total_sales_price,
    avg_net_profit,
    distinct_orders,
    min_wholesale_cost,
    max_wholesale_cost,
    ROW_NUMBER() OVER (ORDER BY total_sales_price DESC) AS row_num
FROM agg
ORDER BY total_sales_price DESC
LIMIT 100

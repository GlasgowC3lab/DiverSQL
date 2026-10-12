WITH joined AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cs.cs_ext_sales_price,
        ss.ss_ext_sales_price,
        sr.sr_return_amt,
        i.i_category,
        sm.sm_type,
        hd_ref.hd_income_band_sk AS hd_income_band_sk
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN household_demographics hd_cs
        ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
           AND sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    WHERE cr.cr_return_amount > 30
      AND cr.cr_fee > 20
      AND cr.cr_return_ship_cost < 200
      AND i.i_current_price BETWEEN 10 AND 100
      AND sm.sm_type = 'AIR'
      AND ss.ss_ext_sales_price > 500
      AND sr.sr_return_amt > 1000
)
SELECT
    i_category,
    sm_type,
    hd_income_band_sk,
    COUNT(DISTINCT cr_order_number) AS distinct_orders,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_amount) AS avg_return_amount,
    SUM(cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss_ext_sales_price) AS total_store_sales,
    SUM(sr_return_amt) AS total_store_returns,
    MIN(cr_return_amount) AS min_return,
    MAX(cr_return_amount) AS max_return
FROM joined
GROUP BY i_category, sm_type, hd_income_band_sk
ORDER BY total_return_amount DESC
LIMIT 100

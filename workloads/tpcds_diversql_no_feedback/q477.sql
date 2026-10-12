WITH
    sales_agg AS (
        SELECT
            cs_order_number,
            cs_item_sk,
            cs_ship_mode_sk,
            cs_bill_hdemo_sk,
            cs_ship_hdemo_sk,
            SUM(cs_ext_sales_price) AS sales_ext,
            SUM(cs_net_paid_inc_ship) AS net_paid_inc_ship,
            SUM(cs_quantity) AS total_qty
        FROM catalog_sales
        WHERE cs_ext_sales_price > 0
        GROUP BY cs_order_number, cs_item_sk, cs_ship_mode_sk, cs_bill_hdemo_sk, cs_ship_hdemo_sk
    ),
    returns_agg AS (
        SELECT
            cr_order_number,
            cr_item_sk,
            cr_ship_mode_sk,
            cr_refunded_hdemo_sk,
            cr_returning_hdemo_sk,
            SUM(cr_return_amount) AS return_amount,
            SUM(cr_return_quantity) AS return_qty
        FROM catalog_returns
        WHERE cr_return_amount > 0
        GROUP BY cr_order_number, cr_item_sk, cr_ship_mode_sk, cr_refunded_hdemo_sk, cr_returning_hdemo_sk
    ),
    discount_levels AS (
        SELECT * FROM (VALUES (1), (2), (3)) AS t(tier)
    )
SELECT
    ib_bill.ib_income_band_sk AS income_band_sk,
    sm_ship.sm_ship_mode_id AS ship_mode_id,
    dl.tier AS discount_tier,
    SUM(s.sales_ext) AS total_sales,
    SUM(r.return_amount) AS total_returns,
    COUNT(DISTINCT s.cs_order_number) AS orders_cnt,
    ROW_NUMBER() OVER (PARTITION BY ib_bill.ib_income_band_sk ORDER BY SUM(s.sales_ext) DESC) AS rn
FROM sales_agg s
JOIN returns_agg r
    ON s.cs_order_number = r.cr_order_number
   AND s.cs_item_sk = r.cr_item_sk
JOIN household_demographics hd_bill
    ON s.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON s.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN household_demographics hd_refund
    ON r.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN household_demographics hd_return
    ON r.cr_returning_hdemo_sk = hd_return.hd_demo_sk
JOIN ship_mode sm_ship
    ON s.cs_ship_mode_sk = sm_ship.sm_ship_mode_sk
JOIN ship_mode sm_return
    ON r.cr_ship_mode_sk = sm_return.sm_ship_mode_sk
JOIN income_band ib_bill
    ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
JOIN income_band ib_ship
    ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
CROSS JOIN discount_levels dl
GROUP BY GROUPING SETS (
    (ib_bill.ib_income_band_sk, sm_ship.sm_ship_mode_id, dl.tier),
    (ib_bill.ib_income_band_sk, dl.tier),
    (dl.tier),
    ()
)
HAVING SUM(s.sales_ext) > 1000
ORDER BY total_sales DESC
LIMIT 100

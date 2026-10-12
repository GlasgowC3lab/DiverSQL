WITH
    filtered_returns AS (
        SELECT
            cr.cr_refunded_hdemo_sk AS hd_demo_sk,
            cr.cr_return_amount,
            cr.cr_return_quantity,
            cr.cr_returned_date_sk
        FROM catalog_returns cr
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE ib.ib_upper_bound <= 130000
          AND cr.cr_return_amount > 100.00
    ),
    filtered_sales AS (
        SELECT
            ss.ss_hdemo_sk AS hd_demo_sk,
            ss.ss_ext_sales_price,
            ss.ss_quantity,
            ss.ss_sold_date_sk
        FROM store_sales ss
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE ib.ib_lower_bound >= 90000
          AND ss.ss_ext_sales_price > 500.00
    ),
    intersected_households AS (
        SELECT hd_demo_sk FROM filtered_returns
        INTERSECT
        SELECT hd_demo_sk FROM filtered_sales
    ),
    agg AS (
        SELECT
            ib.ib_income_band_sk AS ib_income_band_sk,
            hd.hd_vehicle_count,
            SUM(fr.cr_return_amount) AS total_return_amount,
            SUM(fs.ss_ext_sales_price) AS total_sales_amount
        FROM intersected_households ih
        JOIN household_demographics hd ON ih.hd_demo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN filtered_returns fr ON ih.hd_demo_sk = fr.hd_demo_sk
        LEFT JOIN filtered_sales fs ON ih.hd_demo_sk = fs.hd_demo_sk
        GROUP BY ROLLUP (ib.ib_income_band_sk, hd.hd_vehicle_count)
    )
SELECT
    ib_income_band_sk,
    hd_vehicle_count,
    total_return_amount,
    total_sales_amount,
    ROW_NUMBER() OVER (ORDER BY total_sales_amount DESC NULLS LAST) AS rn
FROM agg
ORDER BY total_sales_amount DESC
LIMIT 100

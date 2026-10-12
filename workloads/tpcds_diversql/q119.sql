WITH sales_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_hdemo_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_qty
    FROM store_sales ss
    GROUP BY
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_hdemo_sk
)
SELECT
    d_sales.d_year,
    s.s_store_name,
    i.i_item_id,
    i.i_category,
    hd_ss.hd_buy_potential,
    sales_agg.total_sales,
    sales_agg.total_qty,
    cr_latest.return_amount,
    cr_latest.return_month_seq,
    cr_latest.refunded_income_band_sk
FROM sales_agg
JOIN date_dim d_sales
    ON sales_agg.ss_sold_date_sk = d_sales.d_date_sk
JOIN item i
    ON sales_agg.ss_item_sk = i.i_item_sk
JOIN household_demographics hd_ss
    ON sales_agg.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN store s
    ON sales_agg.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
CROSS JOIN LATERAL (
    SELECT
        cr.cr_return_amount AS return_amount,
        d_ret.d_month_seq AS return_month_seq,
        hd_ref.hd_income_band_sk AS refunded_income_band_sk
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    WHERE cr.cr_item_sk = i.i_item_sk
    ORDER BY cr.cr_returned_date_sk DESC
    LIMIT 1
) AS cr_latest
WHERE d_sales.d_year BETWEEN 1999 AND 2001
  AND s.s_tax_percentage > 0.05
  AND hd_ss.hd_vehicle_count >= 0
GROUP BY
    d_sales.d_year,
    s.s_store_name,
    i.i_item_id,
    i.i_category,
    hd_ss.hd_buy_potential,
    sales_agg.total_sales,
    sales_agg.total_qty,
    cr_latest.return_amount,
    cr_latest.return_month_seq,
    cr_latest.refunded_income_band_sk
ORDER BY
    sales_agg.total_sales DESC,
    d_sales.d_year,
    s.s_store_name
LIMIT 100

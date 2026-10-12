WITH
    sampled_cr AS (
        SELECT *
        FROM catalog_returns
        TABLESAMPLE BERNOULLI (10)
    ),
    full_join_reason AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_returned_time_sk,
            cr.cr_item_sk,
            cr.cr_refunded_hdemo_sk,
            cr.cr_returning_hdemo_sk,
            cr.cr_catalog_page_sk,
            cr.cr_reason_sk,
            cr.cr_return_amount,
            cr.cr_return_quantity,
            r.r_reason_desc
        FROM sampled_cr cr
        FULL OUTER JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
    ),
    diff_items AS (
        SELECT cr_item_sk
        FROM catalog_returns
        EXCEPT
        SELECT wr_item_sk
        FROM web_returns
    ),
    final_data AS (
        SELECT
            fr.cr_returned_date_sk,
            fr.cr_returned_time_sk,
            fr.cr_item_sk,
            fr.cr_return_amount,
            fr.cr_return_quantity,
            fr.r_reason_desc,
            d.d_year,
            d.d_month_seq,
            t.t_hour,
            i.i_category,
            i.i_current_price,
            hd.hd_income_band_sk,
            ib.ib_upper_bound,
            cp.cp_department,
            cp.cp_catalog_number,
            wp.wp_url
        FROM full_join_reason fr
        JOIN date_dim d
            ON fr.cr_returned_date_sk = d.d_date_sk
        JOIN time_dim t
            ON fr.cr_returned_time_sk = t.t_time_sk
        JOIN item i
            ON fr.cr_item_sk = i.i_item_sk
        JOIN household_demographics hd
            ON fr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN catalog_page cp
            ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN web_returns wr
            ON d.d_date_sk = wr.wr_returned_date_sk
            AND t.t_time_sk = wr.wr_returned_time_sk
            AND i.i_item_sk = wr.wr_item_sk
        LEFT JOIN web_page wp
            ON wr.wr_web_page_sk = wp.wp_web_page_sk
        WHERE
            d.d_year = 2001
            AND d.d_month_seq BETWEEN 1200 AND 1300
            AND i.i_current_price > 50
            AND ib.ib_upper_bound >= 80000
            AND fr.r_reason_desc LIKE '%color%'
            AND t.t_hour BETWEEN 9 AND 17
            AND fr.cr_item_sk IN (SELECT cr_item_sk FROM diff_items)
    )
SELECT
    d_year,
    i_category,
    cp_department,
    r_reason_desc,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_return_quantity) AS total_return_qty,
    AVG(i_current_price) AS avg_item_price,
    MIN(ib_upper_bound) AS min_income_upper,
    COUNT(DISTINCT cr_item_sk) AS distinct_items,
    MAX(cp_catalog_number) AS max_catalog_number,
    COUNT(*) AS total_rows
FROM final_data
GROUP BY
    d_year,
    i_category,
    cp_department,
    r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100

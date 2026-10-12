WITH combined_returns AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        cr.cr_catalog_page_sk AS catalog_page_sk,
        cr.cr_ship_mode_sk AS ship_mode_sk,
        cr.cr_refunded_hdemo_sk AS refunded_hdemo_sk,
        cr.cr_returning_hdemo_sk AS returning_hdemo_sk
    FROM catalog_returns cr
    UNION ALL
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_item_sk AS item_sk,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_return_amt AS return_amount,
        wr.wr_net_loss AS net_loss,
        CAST(NULL AS integer) AS catalog_page_sk,
        CAST(NULL AS integer) AS ship_mode_sk,
        wr.wr_refunded_hdemo_sk AS refunded_hdemo_sk,
        wr.wr_returning_hdemo_sk AS returning_hdemo_sk
    FROM web_returns wr
)
SELECT
    d.d_year,
    cp.cp_department,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(crw.return_amount) AS total_return_amount,
    SUM(crw.return_quantity) AS total_return_qty,
    AVG(crw.return_amount) AS avg_return_amount,
    COUNT(*) AS return_cnt,
    MIN(crw.return_amount) AS min_return_amount,
    MAX(crw.return_amount) AS max_return_amount
FROM combined_returns crw
LEFT JOIN date_dim d
    ON crw.date_sk = d.d_date_sk
LEFT JOIN item i
    ON crw.item_sk = i.i_item_sk
LEFT JOIN catalog_page cp
    ON crw.catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm
    ON crw.ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN household_demographics hd_refunded
    ON crw.refunded_hdemo_sk = hd_refunded.hd_demo_sk
LEFT JOIN household_demographics hd_returning
    ON crw.returning_hdemo_sk = hd_returning.hd_demo_sk
LEFT JOIN income_band ib
    ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN promotion p
    ON i.i_item_sk = p.p_item_sk
   AND d.d_date_sk = p.p_start_date_sk
WHERE d.d_year = 2000
  AND i.i_manager_id = 63
  AND hd_refunded.hd_buy_potential = '>10000'
  AND ib.ib_lower_bound >= 50000
GROUP BY GROUPING SETS (
    (d.d_year, cp.cp_department, ib.ib_lower_bound, ib.ib_upper_bound),
    (d.d_year, cp.cp_department),
    (d.d_year),
    ()
)
ORDER BY total_return_amount DESC
LIMIT 100

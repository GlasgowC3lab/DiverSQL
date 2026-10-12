WITH cat_ret AS (
    SELECT
        d.d_year AS year,
        sm.sm_code AS ship_mode_code,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        cd.cd_gender AS gender,
        hd.hd_income_band_sk AS income_band,
        cc.cc_name AS call_center_name,
        w.w_warehouse_name AS warehouse_name,
        NULL AS web_name,
        NULL AS web_return_amount
    FROM tpcds.catalog_returns cr
    TABLESAMPLE BERNOULLI (10)
    JOIN tpcds.date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND sm.sm_code = 'AIR'
      AND cc.cc_state = 'CA'
      AND w.w_state = 'CA'
),
store_ret AS (
    SELECT
        d.d_year AS year,
        NULL AS ship_mode_code,
        sr.sr_return_amt AS return_amount,
        sr.sr_net_loss AS net_loss,
        cd.cd_gender AS gender,
        hd.hd_income_band_sk AS income_band,
        cc.cc_name AS call_center_name,
        NULL AS warehouse_name,
        ws.web_name AS web_name,
        wr.wr_return_amt AS web_return_amount
    FROM tpcds.store_returns sr
    FULL OUTER JOIN tpcds.date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN tpcds.customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN tpcds.household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN tpcds.call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_site ws ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'F'
      AND hd.hd_income_band_sk = 5
),
unioned AS (
    SELECT * FROM cat_ret
    UNION DISTINCT
    SELECT * FROM store_ret
)
SELECT
    year,
    ship_mode_code,
    CASE WHEN net_loss > 0 THEN 'Loss' ELSE 'Profit' END AS loss_category,
    SUM(return_amount) AS total_return_amount,
    AVG(net_loss) AS avg_net_loss,
    COUNT(*) AS transaction_cnt,
    MIN(return_amount) AS min_return,
    MAX(return_amount) AS max_return,
    (SELECT COUNT(*) FROM tpcds.web_site ws_sub WHERE ws_sub.web_state = 'CA') AS ca_web_site_count
FROM unioned
WHERE year IN (SELECT d_year FROM tpcds.date_dim WHERE d_qoy = 2)
GROUP BY
    year,
    ship_mode_code,
    CASE WHEN net_loss > 0 THEN 'Loss' ELSE 'Profit' END
ORDER BY total_return_amount DESC
LIMIT 100

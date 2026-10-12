WITH
    catalog_agg AS (
        SELECT
            cr_call_center_sk,
            cr_returned_date_sk,
            SUM(cr_return_amount) AS total_cr_amount,
            SUM(cr_return_quantity) AS total_cr_qty,
            COUNT(*) AS cnt_cr
        FROM catalog_returns
        WHERE cr_return_amount > 0
          AND cr_return_quantity > 0
        GROUP BY cr_call_center_sk, cr_returned_date_sk
    ),
    store_agg AS (
        SELECT
            sr_returned_date_sk,
            sr_cdemo_sk,
            SUM(sr_return_amt) AS total_sr_amount,
            SUM(sr_return_quantity) AS total_sr_qty,
            COUNT(*) AS cnt_sr
        FROM store_returns
        WHERE sr_return_amt > 0
        GROUP BY sr_returned_date_sk, sr_cdemo_sk
    ),
    call_center_filtered AS (
        SELECT *
        FROM call_center
        WHERE cc_call_center_sk IN (
            SELECT cc_call_center_sk FROM call_center WHERE cc_state = 'CA'
            INTERSECT
            SELECT cr_call_center_sk FROM catalog_returns WHERE cr_return_amount > 500
        )
    ),
    web_site_filtered AS (
        SELECT *
        FROM web_site
        WHERE web_site_sk IN (
            SELECT web_site_sk FROM web_site WHERE web_manager = 'James Austin'
            EXCEPT
            SELECT web_site_sk FROM web_site WHERE web_country <> 'USA'
        )
    )
SELECT
    d_year.d_year,
    cc_filtered.cc_name,
    ws_filtered.web_name,
    SUM(s_agg.total_sr_amount) AS total_store_return_amount,
    SUM(c_agg.total_cr_amount) AS total_catalog_return_amount,
    COUNT(DISTINCT cd.cd_demo_sk) AS distinct_demo_cnt,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM catalog_agg c_agg
JOIN call_center_filtered cc_filtered
    ON c_agg.cr_call_center_sk = cc_filtered.cc_call_center_sk
JOIN date_dim d_year
    ON cc_filtered.cc_open_date_sk = d_year.d_date_sk
JOIN web_site_filtered ws_filtered
    ON ws_filtered.web_open_date_sk = d_year.d_date_sk
JOIN store_agg s_agg
    ON s_agg.sr_returned_date_sk = d_year.d_date_sk
JOIN customer_demographics cd
    ON s_agg.sr_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_credit_rating = 'Low Risk'
  AND cd.cd_dep_count >= 2
  AND d_year.d_year = 2001
  AND ws_filtered.web_manager = 'James Austin'
GROUP BY d_year.d_year, cc_filtered.cc_name, ws_filtered.web_name
ORDER BY total_store_return_amount DESC
LIMIT 100

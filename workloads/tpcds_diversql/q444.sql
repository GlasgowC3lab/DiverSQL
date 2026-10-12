WITH
    hd_income_filtered AS (
        SELECT hd_demo_sk
        FROM household_demographics
        WHERE hd_income_band_sk = 10
    ),
    hd_vehicle_filtered AS (
        SELECT hd_demo_sk
        FROM household_demographics
        WHERE hd_vehicle_count > 2
    ),
    hd_common AS (
        SELECT hd_demo_sk
        FROM hd_income_filtered
        INTERSECT
        SELECT hd_demo_sk
        FROM hd_vehicle_filtered
    ),
    ws_sample AS (
        SELECT *
        FROM web_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    ws_agg AS (
        SELECT
            ws.ws_web_site_sk,
            SUM(ws.ws_ext_sales_price) AS total_sales,
            COUNT(DISTINCT ws.ws_order_number) AS orders,
            CASE WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
        FROM ws_sample ws
        JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
        JOIN income_band ib_bill ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
        JOIN income_band ib_ship ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
        JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
        WHERE hd_bill.hd_demo_sk IN (SELECT hd_demo_sk FROM hd_common)
        GROUP BY ws.ws_web_site_sk
    ),
    sr_agg AS (
        SELECT
            sr.sr_hdemo_sk,
            SUM(sr.sr_return_amt) AS total_return,
            AVG(sr.sr_store_credit) AS avg_credit,
            CASE WHEN SUM(sr.sr_return_amt) > 50000 THEN 'BIG' ELSE 'SMALL' END AS return_category
        FROM store_returns sr
        JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
        JOIN income_band ib_sr ON hd_sr.hd_income_band_sk = ib_sr.ib_income_band_sk
        GROUP BY sr.sr_hdemo_sk
    ),
    site_full AS (
        SELECT ws_site.web_site_sk,
               ws_site.web_city,
               ws_site.web_rec_start_date
        FROM web_site ws_site
        FULL OUTER JOIN (
            SELECT DISTINCT ws_web_site_sk
            FROM web_sales
        ) ws_keys
          ON ws_site.web_site_sk = ws_keys.ws_web_site_sk
    )
SELECT
    COALESCE(wsa.ws_web_site_sk, sra.sr_hdemo_sk) AS key_id,
    COALESCE(wsa.total_sales, 0) AS total_sales,
    COALESCE(sra.total_return, 0) AS total_return,
    wsa.sales_category,
    sra.return_category,
    sf.web_city,
    sf.web_rec_start_date
FROM ws_agg wsa
FULL OUTER JOIN sr_agg sra
    ON wsa.ws_web_site_sk = sra.sr_hdemo_sk
FULL OUTER JOIN site_full sf
    ON sf.web_site_sk = wsa.ws_web_site_sk
UNION DISTINCT
SELECT
    COALESCE(wsa.ws_web_site_sk, sra.sr_hdemo_sk) AS key_id,
    COALESCE(wsa.total_sales, 0) AS total_sales,
    COALESCE(sra.total_return, 0) AS total_return,
    wsa.sales_category,
    sra.return_category,
    sf.web_city,
    sf.web_rec_start_date
FROM sr_agg sra
FULL OUTER JOIN ws_agg wsa
    ON sra.sr_hdemo_sk = wsa.ws_web_site_sk
FULL OUTER JOIN site_full sf
    ON sf.web_site_sk = sra.sr_hdemo_sk
ORDER BY total_sales DESC, total_return DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY

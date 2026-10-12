WITH
store_daily AS (
    SELECT
        s.s_store_sk,
        d.d_year,
        d.d_quarter_seq,
        d.d_date,
        SUM(ss.ss_ext_sales_price) AS store_sales_amt,
        SUM(ss.ss_ext_tax) AS store_tax,
        COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_sk, d.d_year, d.d_quarter_seq, d.d_date
),
web_daily AS (
    SELECT
        ws.ws_web_site_sk,
        d.d_year,
        d.d_quarter_seq,
        d.d_date,
        SUM(ws.ws_ext_sales_price) AS web_sales_amt,
        SUM(ws.ws_ext_tax) AS web_tax,
        COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_web_site_sk, d.d_year, d.d_quarter_seq, d.d_date
),
combined_daily AS (
    SELECT
        COALESCE(st.s_store_sk, -1) AS store_sk,
        COALESCE(wd.ws_web_site_sk, -1) AS web_site_sk,
        COALESCE(st.d_year, wd.d_year) AS year,
        COALESCE(st.d_quarter_seq, wd.d_quarter_seq) AS quarter_seq,
        COALESCE(st.d_date, wd.d_date) AS date,
        st.store_sales_amt,
        wd.web_sales_amt,
        st.store_tax,
        wd.web_tax,
        st.store_txn_cnt,
        wd.web_txn_cnt
    FROM store_daily st
    FULL OUTER JOIN web_daily wd
        ON st.d_date = wd.d_date
        AND st.s_store_sk = wd.ws_web_site_sk
),
daily_with_lag AS (
    SELECT
        cd.*,
        LAG(cd.store_sales_amt) OVER (PARTITION BY cd.store_sk ORDER BY cd.date) AS prev_store_sales,
        LAG(cd.web_sales_amt) OVER (PARTITION BY cd.web_site_sk ORDER BY cd.date) AS prev_web_sales,
        CASE 
            WHEN LAG(cd.store_sales_amt) OVER (PARTITION BY cd.store_sk ORDER BY cd.date) IS NULL
                THEN 0
            ELSE (cd.store_sales_amt - LAG(cd.store_sales_amt) OVER (PARTITION BY cd.store_sk ORDER BY cd.date))
                 / NULLIF(LAG(cd.store_sales_amt) OVER (PARTITION BY cd.store_sk ORDER BY cd.date), 0)
        END AS store_sales_pct_change,
        CASE 
            WHEN LAG(cd.web_sales_amt) OVER (PARTITION BY cd.web_site_sk ORDER BY cd.date) IS NULL
                THEN 0
            ELSE (cd.web_sales_amt - LAG(cd.web_sales_amt) OVER (PARTITION BY cd.web_site_sk ORDER BY cd.date))
                 / NULLIF(LAG(cd.web_sales_amt) OVER (PARTITION BY cd.web_site_sk ORDER BY cd.date), 0)
        END AS web_sales_pct_change
    FROM combined_daily cd
),
top_store AS (
    SELECT
        store_sk,
        year,
        quarter_seq,
        ROW_NUMBER() OVER (PARTITION BY year, quarter_seq ORDER BY SUM(store_sales_amt) DESC) AS rn,
        SUM(store_sales_amt) AS total_store_sales
    FROM daily_with_lag
    WHERE store_sk <> -1
    GROUP BY store_sk, year, quarter_seq
),
top_web AS (
    SELECT
        web_site_sk,
        year,
        quarter_seq,
        ROW_NUMBER() OVER (PARTITION BY year, quarter_seq ORDER BY SUM(web_sales_amt) DESC) AS rn,
        SUM(web_sales_amt) AS total_web_sales
    FROM daily_with_lag
    WHERE web_site_sk <> -1
    GROUP BY web_site_sk, year, quarter_seq
),
combined_top AS (
    SELECT store_sk AS entity_sk, total_store_sales AS total_sales, 'store' AS entity_type, year, quarter_seq
    FROM top_store
    WHERE rn = 1
    UNION ALL
    SELECT web_site_sk AS entity_sk, total_web_sales AS total_sales, 'web' AS entity_type, year, quarter_seq
    FROM top_web
    WHERE rn = 1
),
final_top AS (
    SELECT *
    FROM combined_top
    INTERSECT
    SELECT *
    FROM combined_top
),
final_output AS (
    SELECT
        ft.year,
        ft.quarter_seq,
        ft.entity_type,
        ft.entity_sk,
        ft.total_sales,
        CASE ft.entity_type
            WHEN 'store' THEN COALESCE(s.s_store_name, 'UNKNOWN_STORE')
            WHEN 'web' THEN COALESCE(w.web_name, 'UNKNOWN_WEB')
        END AS entity_name,
        CONCAT('Y', CAST(ft.year AS VARCHAR), '-Q', CAST(ft.quarter_seq AS VARCHAR), '-', UPPER(ft.entity_type), '-', LPAD(CAST(ft.entity_sk AS VARCHAR), 8, '0')) AS strange_key,
        COALESCE(NULLIF(ft.total_sales, 0), -9999.99) AS adjusted_sales,
        CASE ft.entity_type
            WHEN 'store' THEN (SELECT COUNT(DISTINCT ss.ss_customer_sk) FROM store_sales ss WHERE ss.ss_store_sk = ft.entity_sk)
            WHEN 'web' THEN (SELECT COUNT(DISTINCT ws.ws_bill_customer_sk) FROM web_sales ws WHERE ws.ws_web_site_sk = ft.entity_sk)
        END AS distinct_customer_cnt
    FROM final_top ft
    LEFT JOIN store s ON ft.entity_type = 'store' AND ft.entity_sk = s.s_store_sk
    LEFT JOIN web_site w ON ft.entity_type = 'web' AND ft.entity_sk = w.web_site_sk
)
SELECT *
FROM final_output
ORDER BY year DESC, quarter_seq DESC, total_sales DESC
LIMIT 20

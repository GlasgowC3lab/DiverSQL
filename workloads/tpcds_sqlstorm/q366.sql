WITH daily_store_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS daily_sales,
        SUM(ss.ss_net_profit) AS daily_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_quantity) AS total_qty,
        SUM(ss.ss_ext_tax) AS total_tax,
        COUNT(*) AS txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq
),
store_info AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_country,
        s.s_gmt_offset,
        s.s_tax_percentage,
        CONCAT(s.s_city, ', ', s.s_state) AS city_state
    FROM store s
),
sales_ranked AS (
    SELECT
        dss.ss_store_sk,
        dss.ss_sold_date_sk,
        dss.d_date,
        dss.d_year,
        dss.daily_sales,
        dss.daily_profit,
        dss.avg_discount,
        RANK() OVER (PARTITION BY dss.d_year ORDER BY dss.daily_profit DESC) AS profit_rank_year,
        LAG(dss.daily_sales) OVER (PARTITION BY dss.ss_store_sk ORDER BY dss.d_date) AS prev_daily_sales
    FROM daily_store_sales dss
)
SELECT
    si.s_store_sk AS store_sk,
    si.s_store_name AS store_name,
    si.city_state AS city_state,
    sr.d_date AS sale_date,
    sr.daily_sales AS daily_sales,
    sr.daily_profit AS daily_profit,
    sr.avg_discount AS avg_discount,
    sr.profit_rank_year AS profit_rank_year,
    CASE
        WHEN sr.prev_daily_sales IS NULL OR sr.prev_daily_sales = 0 THEN NULL
        ELSE (sr.daily_sales - sr.prev_daily_sales) / NULLIF(sr.prev_daily_sales, 0) * 100
    END AS sales_change_pct,
    (SELECT AVG(ss2.ss_ext_sales_price)
     FROM store_sales ss2
     WHERE ss2.ss_sold_date_sk = sr.ss_sold_date_sk
       AND ss2.ss_store_sk <> sr.ss_store_sk) AS avg_sales_other_stores,
    COALESCE(si.s_state, 'UNKNOWN') AS state_or_unknown,
    CONCAT('Store ', COALESCE(si.s_store_name, 'N/A'), ' - Rank ', COALESCE(CAST(sr.profit_rank_year AS VARCHAR), 'NA')) AS label
FROM sales_ranked sr
LEFT JOIN store_info si ON sr.ss_store_sk = si.s_store_sk
WHERE sr.daily_profit > 0

UNION ALL

SELECT
    s.s_store_sk,
    s.s_store_name,
    CONCAT(s.s_city, ', ', s.s_state),
    d.d_date,
    CAST(0.0 AS decimal(7,2)),
    CAST(0.0 AS decimal(7,2)),
    CAST(NULL AS decimal(7,2)),
    CAST(NULL AS integer),
    CAST(NULL AS double),
    CAST(NULL AS decimal(7,2)),
    s.s_state,
    CONCAT('Store ', s.s_store_name, ' - No Sales')
FROM store s
CROSS JOIN (SELECT d_date, d_date_sk FROM date_dim WHERE d_year = 2000 AND d_month_seq = 12) d
WHERE NOT EXISTS (
    SELECT 1
    FROM store_sales ss
    WHERE ss.ss_store_sk = s.s_store_sk
      AND ss.ss_sold_date_sk = d.d_date_sk
)
ORDER BY store_sk, sale_date

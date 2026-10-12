WITH date_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_sk AS store_sk,
        s.s_store_name AS store_name,
        SUM(ss.ss_net_paid) FILTER (WHERE ss.ss_quantity > 0) AS store_net_paid,
        SUM(ss.ss_net_profit) FILTER (WHERE ss.ss_quantity > 0) AS store_net_profit,
        COUNT(*) FILTER (WHERE ss.ss_quantity > 0) AS store_txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, d.d_month_seq, s.s_store_sk, s.s_store_name
), web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        w.web_site_sk AS web_site_sk,
        w.web_name,
        SUM(ws.ws_net_paid) FILTER (WHERE ws.ws_quantity > 0) AS web_net_paid,
        SUM(ws.ws_net_profit) FILTER (WHERE ws.ws_quantity > 0) AS web_net_profit,
        COUNT(*) FILTER (WHERE ws.ws_quantity > 0) AS web_txn_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_name LIKE '%Online%' ESCAPE '\\'
      AND d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, d.d_month_seq, w.web_site_sk, w.web_name
), combined AS (
    SELECT
        COALESCE(ds.d_year, wa.d_year) AS d_year,
        COALESCE(ds.d_month_seq, wa.d_month_seq) AS d_month_seq,
        ds.store_sk,
        wa.web_site_sk,
        ds.store_net_paid,
        wa.web_net_paid,
        ds.store_net_profit,
        wa.web_net_profit,
        ds.store_txn_cnt,
        wa.web_txn_cnt,
        ds.store_name,
        wa.web_name,
        COALESCE(ds.store_name, wa.web_name) AS chosen_name,
        COALESCE(ds.store_name, 'UNKNOWN') || ' / ' || COALESCE(wa.web_name, 'UNKNOWN') AS combined_name,
        ROW_NUMBER() OVER (
            PARTITION BY COALESCE(ds.d_year, wa.d_year)
            ORDER BY (COALESCE(ds.store_net_profit, 0) - COALESCE(wa.web_net_profit, 0)) DESC
        ) AS profit_rank,
        CASE
            WHEN COALESCE(ds.store_txn_cnt, 0) > 0 AND COALESCE(wa.web_txn_cnt, 0) > 0 THEN 'BOTH'
            WHEN COALESCE(ds.store_txn_cnt, 0) > 0 THEN 'STORE_ONLY'
            WHEN COALESCE(wa.web_txn_cnt, 0) > 0 THEN 'WEB_ONLY'
            ELSE 'NONE'
        END AS source_flag,
        NULLIF(COALESCE(ds.store_name, wa.web_name), '') AS non_empty_name,
        (COALESCE(ds.store_net_profit, 0) - COALESCE(wa.web_net_profit, 0)) AS net_profit_diff,
        (COALESCE(ds.store_net_paid, 0) - COALESCE(wa.web_net_paid, 0)) AS net_paid_diff
    FROM date_sales ds
    FULL OUTER JOIN web_sales_agg wa
        ON ds.d_year = wa.d_year
       AND ds.d_month_seq = wa.d_month_seq
)
SELECT
    c.combined_name,
    c.d_year,
    c.d_month_seq,
    c.net_paid_diff,
    c.net_profit_diff,
    c.source_flag,
    CASE
        WHEN c.store_sk IS NOT NULL
         AND EXISTS (
             SELECT 1 FROM store_returns sr
             WHERE sr.sr_store_sk = c.store_sk AND sr.sr_return_quantity > 0
         )
        THEN 'HAS_RET'
        ELSE 'NO_RET'
    END AS return_flag,
    c.profit_rank,
    (SELECT AVG(c2.net_profit_diff) FROM combined c2 WHERE c2.d_year = c.d_year) AS avg_year_profit_diff,
    SUM(c.net_profit_diff) OVER (PARTITION BY c.d_year) AS sum_profit_diff_year,
    TRY(c.net_paid_diff / (c.net_paid_diff - c.net_paid_diff)) AS dangerous_div,
    REPLACE(REVERSE(c.combined_name), ' ', '_') AS rev_name_underscored,
    COALESCE(NULLIF(c.combined_name, 'UNKNOWN / UNKNOWN'), 'MISSING') AS non_null_combined_name
FROM combined c
WHERE (c.net_profit_diff > 0 AND c.profit_rank <= 5)
   OR (c.source_flag = 'NONE' AND c.non_empty_name IS NULL)
UNION ALL
SELECT
    'TOTAL' AS combined_name,
    NULL AS d_year,
    NULL AS d_month_seq,
    SUM(net_paid_diff) AS net_paid_diff,
    SUM(net_profit_diff) AS net_profit_diff,
    'AGG' AS source_flag,
    NULL AS return_flag,
    NULL AS profit_rank,
    AVG(net_profit_diff) AS avg_year_profit_diff,
    SUM(net_profit_diff) AS sum_profit_diff_year,
    NULL AS dangerous_div,
    '' AS rev_name_underscored,
    '' AS non_null_combined_name
FROM combined
WHERE net_profit_diff IS NOT NULL
ORDER BY d_year DESC NULLS LAST, d_month_seq, profit_rank
LIMIT 100

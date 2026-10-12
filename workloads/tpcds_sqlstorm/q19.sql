WITH
store_sales_agg AS (
    SELECT
        ss_sold_date_sk AS date_sk,
        ss_store_sk AS store_sk,
        SUM(ss_net_paid) AS store_net_paid,
        SUM(ss_net_profit) AS store_net_profit,
        COUNT(*) AS store_txns,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY ss_sold_date_sk) AS store_seq
    FROM store_sales
    WHERE ss_sold_date_sk IS NOT NULL
    GROUP BY ss_sold_date_sk, ss_store_sk
),
catalog_sales_agg AS (
    SELECT
        cs_sold_date_sk AS date_sk,
        cs_call_center_sk AS store_sk,
        SUM(cs_net_paid) AS cat_net_paid,
        SUM(cs_net_profit) AS cat_net_profit,
        COUNT(*) AS cat_txns
    FROM catalog_sales
    WHERE cs_sold_date_sk IS NOT NULL
    GROUP BY cs_sold_date_sk, cs_call_center_sk
),
web_sales_agg AS (
    SELECT
        ws_sold_date_sk AS date_sk,
        ws_web_site_sk AS store_sk,
        SUM(ws_net_paid) AS web_net_paid,
        SUM(ws_net_profit) AS web_net_profit,
        COUNT(*) AS web_txns
    FROM web_sales
    WHERE ws_sold_date_sk IS NOT NULL
    GROUP BY ws_sold_date_sk, ws_web_site_sk
),
combined AS (
    SELECT
        COALESCE(s.date_sk, c.date_sk, w.date_sk) AS date_sk,
        COALESCE(s.store_sk, c.store_sk, w.store_sk) AS store_sk,
        s.store_net_paid,
        s.store_net_profit,
        s.store_txns,
        c.cat_net_paid,
        c.cat_net_profit,
        c.cat_txns,
        w.web_net_paid,
        w.web_net_profit,
        w.web_txns
    FROM store_sales_agg s
    FULL OUTER JOIN catalog_sales_agg c
        ON s.date_sk = c.date_sk AND s.store_sk = c.store_sk
    FULL OUTER JOIN web_sales_agg w
        ON COALESCE(s.date_sk, c.date_sk) = w.date_sk
           AND COALESCE(s.store_sk, c.store_sk) = w.store_sk
),
date_store_info AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        CONCAT(
            CASE WHEN s.s_store_name IS NULL THEN 'UNKNOWN' ELSE s.s_store_name END,
            '_',
            COALESCE(s.s_state, 'ZZ')
        ) AS store_label
    FROM date_dim d
    LEFT JOIN store s
        ON s.s_store_sk = (d.d_date_sk % 1000) + 1
)
SELECT
    ds.store_label,
    ds.d_date,
    COALESCE(SUM(comb.store_net_paid), 0) + COALESCE(SUM(comb.cat_net_paid), 0) + COALESCE(SUM(comb.web_net_paid), 0) AS total_net_paid,
    COALESCE(SUM(comb.store_net_profit), 0) + COALESCE(SUM(comb.cat_net_profit), 0) + COALESCE(SUM(comb.web_net_profit), 0) AS total_net_profit,
    CASE
        WHEN (COALESCE(SUM(comb.store_net_paid), 0) + COALESCE(SUM(comb.cat_net_paid), 0) + COALESCE(SUM(comb.web_net_paid), 0)) = 0 THEN NULL
        ELSE (COALESCE(SUM(comb.store_net_profit), 0) + COALESCE(SUM(comb.cat_net_profit), 0) + COALESCE(SUM(comb.web_net_profit), 0)) /
             NULLIF(COALESCE(SUM(comb.store_net_paid), 0) + COALESCE(SUM(comb.cat_net_paid), 0) + COALESCE(SUM(comb.web_net_paid), 0), 0)
    END AS profit_margin,
    LAG(COALESCE(SUM(comb.store_net_profit), 0) + COALESCE(SUM(comb.cat_net_profit), 0) + COALESCE(SUM(comb.web_net_profit), 0))
        OVER (PARTITION BY ds.s_store_sk ORDER BY ds.d_date) AS prior_day_profit,
    CASE
        WHEN MIN(ds.d_year) BETWEEN 1998 AND 2000 THEN '1990s'
        WHEN MIN(ds.d_year) BETWEEN 2001 AND 2005 THEN '2000s'
        ELSE 'Other'
    END AS era,
    CONCAT('Store-', COALESCE(CAST(ds.s_store_sk AS VARCHAR), '-1'), '/', COALESCE(ds.s_state, 'XX')) AS store_ref,
    regexp_replace(ds.store_label, '[^A-Za-z0-9_]', '') AS clean_store_label,
    ((COALESCE(SUM(comb.store_net_paid), 0) + COALESCE(SUM(comb.cat_net_paid), 0) + COALESCE(SUM(comb.web_net_paid), 0) > 0)
     <> (COALESCE(SUM(comb.store_net_profit), 0) + COALESCE(SUM(comb.cat_net_profit), 0) + COALESCE(SUM(comb.web_net_profit), 0) < 0)) AS interesting_flag,
    MAX(sr.max_ticket_number) AS max_ticket_number
FROM combined comb
JOIN date_store_info ds
    ON ds.d_date_sk = comb.date_sk AND ds.s_store_sk = comb.store_sk
LEFT JOIN LATERAL (
    SELECT MAX(ss_ticket_number) AS max_ticket_number
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk = ds.d_date_sk
      AND ss.ss_store_sk = ds.s_store_sk
) sr ON TRUE
WHERE
    ((ds.d_month_seq % 2) = 0 OR ds.d_month_seq IS NULL)
GROUP BY
    ROLLUP(ds.store_label, ds.d_date, ds.s_store_sk, ds.s_state)
HAVING
    SUM(COALESCE(comb.store_net_profit, 0) + COALESCE(comb.cat_net_profit, 0) + COALESCE(comb.web_net_profit, 0)) > 0
    AND (COALESCE(SUM(comb.store_txns), 0) + COALESCE(SUM(comb.cat_txns), 0) + COALESCE(SUM(comb.web_txns), 0) > 1
         OR (SUM(comb.store_txns) IS NULL AND SUM(comb.cat_txns) IS NULL AND SUM(comb.web_txns) IS NULL))
ORDER BY
    ds.s_store_sk NULLS LAST,
    ds.d_date

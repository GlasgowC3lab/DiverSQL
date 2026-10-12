WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY ss.ss_store_sk, ss.ss_item_sk
),
returns_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_item_sk,
        SUM(sr.sr_return_amt) AS total_returns,
        COUNT(*) AS returns_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY sr.sr_store_sk, sr.sr_item_sk
)
SELECT
    s.s_store_name,
    i.i_category,
    COALESCE(sa.total_sales, 0) AS total_sales,
    COALESCE(sa.total_profit, 0) AS total_profit,
    COALESCE(ra.total_returns, 0) AS total_returns,
    CASE WHEN COALESCE(sa.sales_cnt, 0) = 0 THEN 0
         ELSE COALESCE(ra.returns_cnt, 0) * 100.0 / COALESCE(sa.sales_cnt, 0)
    END AS return_rate_pct
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
    ON sa.ss_store_sk = ra.sr_store_sk
   AND sa.ss_item_sk = ra.sr_item_sk
JOIN store s
    ON COALESCE(sa.ss_store_sk, ra.sr_store_sk) = s.s_store_sk
JOIN item i
    ON COALESCE(sa.ss_item_sk, ra.sr_item_sk) = i.i_item_sk
ORDER BY total_sales DESC
LIMIT 100

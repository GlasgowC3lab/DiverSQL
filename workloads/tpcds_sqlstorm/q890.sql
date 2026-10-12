WITH
    sales_agg AS (
        SELECT
            s.s_store_sk,
            d.d_date,
            d.d_year,
            SUM(ss.ss_ext_sales_price) AS store_sales,
            SUM(ss.ss_net_profit) AS store_profit,
            COUNT(*) AS store_txn_cnt,
            MAX(ss.ss_ticket_number) AS max_ticket,
            MIN(ss.ss_ticket_number) AS min_ticket
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE ss.ss_sold_date_sk IS NOT NULL
        GROUP BY s.s_store_sk, d.d_date, d.d_year
    ),
    returns_agg AS (
        SELECT
            s.s_store_sk,
            d.d_date,
            d.d_year,
            SUM(sr.sr_return_amt_inc_tax) AS store_returns,
            SUM(sr.sr_net_loss) AS store_net_loss,
            COUNT(*) AS store_return_cnt
        FROM store_returns sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        GROUP BY s.s_store_sk, d.d_date, d.d_year
    ),
    combined AS (
        SELECT
            COALESCE(sa.s_store_sk, ra.s_store_sk) AS store_sk,
            COALESCE(sa.d_date, ra.d_date) AS sale_date,
            COALESCE(sa.d_year, ra.d_year) AS sale_year,
            COALESCE(sa.store_sales, 0) AS store_sales,
            COALESCE(ra.store_returns, 0) AS store_returns,
            COALESCE(sa.store_profit, 0) - COALESCE(ra.store_net_loss, 0) AS net_profit_adj,
            COALESCE(sa.store_txn_cnt, 0) AS txn_cnt,
            COALESCE(ra.store_return_cnt, 0) AS return_cnt,
            CASE
                WHEN COALESCE(sa.store_sales, 0) = 0 THEN NULL
                ELSE (COALESCE(sa.store_sales, 0) - COALESCE(ra.store_returns, 0)) / NULLIF(COALESCE(sa.store_sales, 0), 0)
            END AS sales_return_ratio,
            CONCAT('Store_', CAST(COALESCE(sa.s_store_sk, ra.s_store_sk) AS varchar), '_', CAST(COALESCE(sa.d_year, ra.d_year) AS varchar)) AS store_year_label
        FROM sales_agg sa
        FULL OUTER JOIN returns_agg ra
            ON sa.s_store_sk = ra.s_store_sk
            AND sa.d_date = ra.d_date
    ),
    ranked AS (
        SELECT
            c.*,
            ROW_NUMBER() OVER (PARTITION BY c.sale_year ORDER BY c.net_profit_adj DESC NULLS LAST) AS profit_rank,
            SUM(c.net_profit_adj) OVER (PARTITION BY c.sale_year ORDER BY c.sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
            AVG(c.sales_return_ratio) OVER (PARTITION BY c.sale_year) AS avg_sales_return_ratio_year
        FROM combined c
        WHERE c.store_sales IS NOT NULL OR c.store_returns IS NOT NULL
    ),
    final AS (
        SELECT
            r.store_sk,
            r.sale_date,
            r.store_year_label,
            r.store_sales,
            r.store_returns,
            r.net_profit_adj,
            r.profit_rank,
            r.cumulative_profit,
            r.avg_sales_return_ratio_year,
            (SELECT MAX(r2.profit_rank) FROM ranked r2 WHERE r2.store_sk = r.store_sk) AS max_rank_for_store,
            CASE
                WHEN r.store_year_label LIKE '%2020%' THEN 'Y2020'
                WHEN r.store_year_label LIKE '%2021%' THEN 'Y2021'
                ELSE 'OTHER'
            END AS year_category,
            (SELECT COUNT(*) FROM store s3 WHERE s3.s_store_name IS NOT NULL AND s3.s_store_sk = r.store_sk) AS store_exists_flag
        FROM ranked r
        WHERE r.profit_rank <= 5
    )
SELECT *
FROM final
UNION ALL
SELECT
    NULL AS store_sk,
    NULL AS sale_date,
    'TOTAL' AS store_year_label,
    SUM(store_sales) AS store_sales,
    SUM(store_returns) AS store_returns,
    SUM(net_profit_adj) AS net_profit_adj,
    NULL AS profit_rank,
    SUM(cumulative_profit) AS cumulative_profit,
    AVG(avg_sales_return_ratio_year) AS avg_sales_return_ratio_year,
    NULL AS max_rank_for_store,
    'ALL' AS year_category,
    COUNT(DISTINCT store_sk) AS store_exists_flag
FROM final
WHERE store_sk IS NOT NULL
GROUP BY store_year_label
ORDER BY sale_date NULLS LAST, profit_rank NULLS LAST

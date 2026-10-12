WITH
    sales_cte AS (
        SELECT ss.ss_store_sk AS store_sk,
               SUM(ss.ss_net_paid) AS total_sales
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY ss.ss_store_sk
    ),
    returns_cte AS (
        SELECT sr.sr_store_sk AS store_sk,
               SUM(sr.sr_return_amt) AS total_returns
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY sr.sr_store_sk
    ),
    full_join_cte AS (
        SELECT COALESCE(s.store_sk, r.store_sk) AS store_sk,
               s.total_sales,
               r.total_returns
        FROM sales_cte s
        FULL OUTER JOIN returns_cte r
          ON s.store_sk = r.store_sk
    ),
    intersect_store_ids AS (
        SELECT ss.ss_store_sk AS store_sk
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        INTERSECT
        SELECT sr.sr_store_sk
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    )
SELECT
    f.store_sk,
    COALESCE(f.total_sales, 0) AS total_sales,
    COALESCE(f.total_returns, 0) AS total_returns,
    CASE
        WHEN f.total_sales IS NULL THEN 'No Sales'
        WHEN f.total_returns IS NULL THEN 'No Returns'
        WHEN f.total_sales > f.total_returns THEN 'Profit'
        ELSE 'Loss'
    END AS profitability,
    (SELECT COUNT(DISTINCT ss2.ss_promo_sk)
     FROM store_sales ss2
     JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
     WHERE ss2.ss_store_sk = f.store_sk
       AND d2.d_year = 2001) AS promo_count
FROM full_join_cte f
WHERE EXISTS (SELECT 1 FROM intersect_store_ids i WHERE i.store_sk = f.store_sk)
ORDER BY profitability DESC, total_sales DESC

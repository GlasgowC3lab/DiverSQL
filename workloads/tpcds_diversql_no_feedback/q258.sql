WITH sales_by_store_year AS (
    SELECT
        ss.ss_store_sk AS store_id,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_count
    FROM store_sales AS ss
    JOIN date_dim AS d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
        d.d_current_year = 'Y'               -- filter 1
        AND d.d_weekend = 'N'                 -- filter 2
        AND ss.ss_ext_wholesale_cost > 1500   -- filter 3
        AND ss.ss_ext_tax < 50                -- filter 4
        AND d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'  -- filter 5
    GROUP BY ss.ss_store_sk, d.d_year
),
avg_profit_per_store AS (
    SELECT
        store_id,
        AVG(total_profit) AS avg_profit,
        SUM(total_sales) AS sum_sales,
        SUM(txn_count) AS total_txns
    FROM sales_by_store_year
    GROUP BY store_id
    HAVING AVG(total_profit) > 1000
)
SELECT
    a.store_id,
    a.avg_profit,
    a.sum_sales,
    a.total_txns,
    v.profit_category
FROM avg_profit_per_store AS a
CROSS JOIN (VALUES
    ('HIGH'),
    ('MEDIUM'),
    ('LOW')
) AS v(profit_category)
ORDER BY a.avg_profit DESC
LIMIT 100

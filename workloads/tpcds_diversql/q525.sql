WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        td.t_shift,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales AS ss
    JOIN time_dim AS td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_am_pm = 'PM'
      AND td.t_minute IN (10, 15, 18)
    GROUP BY GROUPING SETS (
        (ss.ss_store_sk, td.t_shift),
        (ss.ss_store_sk)
    )
),
set_a AS (
    SELECT ss_store_sk, t_shift, total_sales
    FROM sales_agg
    WHERE total_sales > 1000
),
set_b AS (
    SELECT ss_store_sk, t_shift, total_sales
    FROM sales_agg
    WHERE total_profit < 0
),
 diff AS (
    SELECT * FROM set_a
    EXCEPT
    SELECT * FROM set_b
),
final AS (
    SELECT
        d.ss_store_sk,
        d.t_shift,
        d.total_sales,
        ROW_NUMBER() OVER (PARTITION BY d.ss_store_sk ORDER BY d.total_sales DESC) AS sales_rank,
        lt.max_total_sales
    FROM diff d
    CROSS JOIN LATERAL (
        SELECT MAX(sa.total_sales) AS max_total_sales
        FROM sales_agg sa
        WHERE sa.ss_store_sk = d.ss_store_sk
    ) AS lt
)
SELECT
    ss_store_sk,
    t_shift,
    total_sales,
    sales_rank,
    max_total_sales
FROM final
ORDER BY total_sales DESC, sales_rank
LIMIT 100

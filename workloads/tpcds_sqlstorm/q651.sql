WITH agg AS (
    SELECT
        d.d_year,
        s.s_store_name,
        s.s_state,
        SUM(ss.ss_net_paid) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, s.s_store_name, s.s_state
)
SELECT
    d_year,
    s_store_name,
    s_state,
    total_sales,
    sales_rank
FROM (
    SELECT
        agg.*,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM agg
) ranked
WHERE sales_rank <= 10
ORDER BY d_year, sales_rank

WITH sales_by_store AS (
    SELECT s.s_store_id,
           s.s_store_name,
           'sales' AS metric_type,
           SUM(ss.ss_net_paid) AS total_amount
    FROM store_sales ss
    RIGHT JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, s.s_store_name
),
returns_by_store AS (
    SELECT s.s_store_id,
           s.s_store_name,
           'returns' AS metric_type,
           SUM(sr.sr_net_loss) AS total_amount
    FROM store_returns sr
    RIGHT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY s.s_store_id, s.s_store_name
)
SELECT s_store_id,
       s_store_name,
       metric_type,
       total_amount
FROM sales_by_store
UNION
SELECT s_store_id,
       s_store_name,
       metric_type,
       total_amount
FROM returns_by_store
ORDER BY s_store_id, metric_type
LIMIT 100

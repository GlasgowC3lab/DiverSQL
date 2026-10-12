WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_net_paid,
        ss.ss_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '(?i)red|blue')
),
aggregated AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        s.s_city AS city,
        d.d_month_seq AS month_seq,
        SUM(fs.ss_net_paid) AS total_net_paid,
        SUM(fs.ss_quantity) AS total_quantity
    FROM filtered_sales fs
    JOIN store s ON fs.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON fs.ss_sold_date_sk = d.d_date_sk
    GROUP BY GROUPING SETS (
        (s.s_store_id, s.s_store_name, s.s_city, d.d_month_seq),
        (s.s_store_id, s.s_store_name, s.s_city)
    )
)
SELECT
    t.store_id,
    t.store_name,
    t.city,
    t.month_seq,
    t.total_net_paid,
    t.total_quantity,
    CONCAT(t.store_name, ' - ', t.city) AS store_full_name,
    t.running_total,
    CASE
        WHEN regexp_like(t.store_name, '^A.*') THEN 'StartsWithA'
        ELSE 'Other'
    END AS name_category
FROM (
    SELECT
        a.store_id,
        a.store_name,
        a.city,
        a.month_seq,
        a.total_net_paid,
        a.total_quantity,
        SUM(a.total_net_paid) OVER (
            PARTITION BY a.store_id
            ORDER BY a.month_seq
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total
    FROM aggregated a
) t
WHERE t.store_id NOT IN (
    SELECT s_store_id FROM store WHERE s_store_name LIKE '%Closed%'
)
ORDER BY t.store_id, t.month_seq
LIMIT 100

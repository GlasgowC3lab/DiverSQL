WITH
store_sales_agg AS (
    SELECT
        s.s_store_id,
        d.d_date,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_net_profit) DESC) AS rn_store_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY s.s_store_id, d.d_date
),
catalog_sales_agg AS (
    SELECT
        cp.cp_catalog_page_id,
        d.d_date,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
        ROW_NUMBER() OVER (PARTITION BY cp.cp_catalog_page_id ORDER BY SUM(cs.cs_net_profit) DESC) AS rn_catalog_profit
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cp.cp_type = 'WEB' OR cp.cp_type IS NULL
    GROUP BY cp.cp_catalog_page_id, d.d_date
),
top_store_sales AS (
    SELECT *
    FROM store_sales_agg
    WHERE rn_store_profit <= 5
),
top_catalog_sales AS (
    SELECT *
    FROM catalog_sales_agg
    WHERE rn_catalog_profit <= 5
),
combined AS (
    SELECT 'STORE' AS src,
        t.s_store_id AS entity_id,
        t.d_date,
        t.total_net_profit,
        t.total_quantity,
        t.avg_sales_price,
        t.distinct_items
    FROM top_store_sales t
    UNION ALL
    SELECT 'CATALOG' AS src,
        t.cp_catalog_page_id AS entity_id,
        t.d_date,
        t.total_net_profit,
        t.total_quantity,
        t.avg_sales_price,
        t.distinct_items
    FROM top_catalog_sales t
),
latest_sales AS (
    SELECT
        s.s_store_id,
        d.d_date,
        COALESCE((
            SELECT MAX(ss2.ss_sold_date_sk)
            FROM store_sales ss2
            WHERE ss2.ss_store_sk = s.s_store_sk
              AND ss2.ss_sold_date_sk <= d.d_date_sk
        ), 0) AS latest_sold_date_sk,
        CASE
            WHEN d.d_year = EXTRACT(year FROM DATE '2024-10-01') THEN 'CURRENT_YEAR'
            ELSE 'PAST_YEAR'
        END AS year_category
    FROM store s
    JOIN date_dim d ON d.d_date BETWEEN DATE '1999-01-01' AND DATE '2002-12-31'
),
store_customer_total_metrics AS (
    SELECT
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS store_sum_net_paid,
        COUNT(*) AS total_sales_rows
    FROM store_sales ss
    GROUP BY ss.ss_store_sk
),
final AS (
    SELECT
        c.src,
        c.entity_id,
        c.d_date,
        c.total_net_profit,
        c.total_quantity,
        c.avg_sales_price,
        c.distinct_items,
        COALESCE(ls.latest_sold_date_sk, 0) AS latest_sold_date_sk,
        COALESCE(ls.year_category, 'UNKNOWN') AS year_category,
        COALESCE(sctm.store_sum_net_paid, 0) AS store_sum_net_paid,
        CASE
            WHEN c.total_net_profit > 0 AND COALESCE(sctm.store_sum_net_paid, 0) <> 0
            THEN c.total_net_profit / sctm.store_sum_net_paid
            ELSE NULL
        END AS profit_to_payment_ratio,
        ROW_NUMBER() OVER (PARTITION BY c.src ORDER BY c.total_net_profit DESC) AS overall_rank,
        CONCAT(COALESCE(CAST(c.entity_id AS VARCHAR), 'UNKNOWN'), '-', COALESCE(ls.year_category, 'NA')) AS composite_key,
        CASE
            WHEN REGEXP_LIKE(CAST(c.entity_id AS VARCHAR), '^\\d+$')
            THEN CAST(c.entity_id AS BIGINT) * 13
            ELSE NULL
        END AS entity_id_hash,
        (SELECT COUNT(*)
         FROM combined c2
         WHERE c2.src = c.src
           AND c2.d_date = c.d_date
           AND c2.total_net_profit > c.total_net_profit) AS higher_profit_count
    FROM combined c
    LEFT JOIN latest_sales ls
        ON c.src = 'STORE' AND ls.s_store_id = c.entity_id
    LEFT JOIN store s
        ON c.src = 'STORE' AND s.s_store_id = c.entity_id
    LEFT JOIN store_customer_total_metrics sctm
        ON s.s_store_sk = sctm.ss_store_sk
    WHERE c.total_net_profit IS NOT NULL
)
SELECT *
FROM final
WHERE (profit_to_payment_ratio IS NOT NULL AND profit_to_payment_ratio > 0.1)
   OR (entity_id_hash IS NOT NULL AND entity_id_hash % 2 = 0)
ORDER BY src, overall_rank
LIMIT 100

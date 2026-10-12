WITH
store_sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        d.d_date AS sales_date,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_orders,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store s
    JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE s.s_country = 'United States'
      AND d.d_year = 2002
    GROUP BY s.s_store_sk, s.s_store_id, d.d_date
),
store_returns_agg AS (
    SELECT
        s.s_store_sk,
        d.d_date AS return_date,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS num_returns
    FROM store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON d.d_date_sk = sr.sr_returned_date_sk
    GROUP BY s.s_store_sk, d.d_date
),
store_recent_sales AS (
    SELECT
        s_store_sk,
        MAX(sales_date) AS latest_sales_date
    FROM store_sales_agg
    GROUP BY s_store_sk
),
sales_combined AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        COALESCE(ssa.sales_date, sra.return_date) AS activity_date,
        COALESCE(ssa.total_net_paid, 0) - COALESCE(sra.total_return_amount, 0) AS net_activity_amount,
        COALESCE(ssa.total_net_profit, 0) - COALESCE(sra.total_return_loss, 0) AS net_activity_profit,
        CASE 
            WHEN COALESCE(ssa.total_quantity,0) = 0 THEN NULL
            ELSE COALESCE(ssa.total_net_paid,0) / NULLIF(ssa.total_quantity,0)
        END AS avg_paid_per_item,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY COALESCE(ssa.sales_date, sra.return_date) DESC) AS rn,
        CONCAT('Store_', s.s_store_id, '_', CAST(EXTRACT(year FROM COALESCE(ssa.sales_date, sra.return_date)) AS VARCHAR)) AS label,
        LAG(COALESCE(ssa.total_net_paid,0)) OVER (PARTITION BY s.s_store_sk ORDER BY COALESCE(ssa.sales_date, sra.return_date)) AS prev_net_paid,
        (SELECT COUNT(*)
         FROM store_sales_agg ss2
         WHERE ss2.s_store_sk = s.s_store_sk
           AND ss2.sales_date < COALESCE(ssa.sales_date, sra.return_date)
        ) AS prior_activity_days,
        CASE
            WHEN TRY_CAST(s.s_store_id AS INTEGER) IS NULL THEN 'Non-numeric ID'
            ELSE 'Numeric ID'
        END AS id_type_label
    FROM store s
    LEFT JOIN store_sales_agg ssa ON ssa.s_store_sk = s.s_store_sk
    LEFT JOIN store_returns_agg sra ON sra.s_store_sk = s.s_store_sk
    WHERE ssa.sales_date IS NOT NULL OR sra.return_date IS NOT NULL
),
catalog_agg AS (
    SELECT
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        CASE WHEN SUM(cs.cs_quantity) = 0 THEN NULL ELSE SUM(cs.cs_net_paid_inc_tax) / SUM(cs.cs_quantity) END AS avg_paid_per_item
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    WHERE cs.cs_sold_date_sk = 2450855
),
catalog_combined AS (
    SELECT
        NULL AS s_store_sk,
        'Catalog_Aggregated' AS s_store_name,
        NULL AS activity_date,
        cat.total_net_paid - cat.total_return_amount AS net_activity_amount,
        cat.total_net_profit - cat.total_return_loss AS net_activity_profit,
        cat.avg_paid_per_item,
        1 AS rn,
        'Catalog_Aggregate' AS label,
        NULL AS prev_net_paid,
        NULL AS prior_activity_days,
        'Aggregated Catalog' AS id_type_label
    FROM catalog_agg cat
    WHERE cat.total_net_paid > 0
)

SELECT *
FROM sales_combined
WHERE (net_activity_amount > 0 AND rn = 1)
   OR (net_activity_amount IS NULL AND label LIKE '%Store_%' ESCAPE '\')
UNION ALL
SELECT *
FROM catalog_combined
ORDER BY net_activity_amount DESC NULLS LAST
LIMIT 100

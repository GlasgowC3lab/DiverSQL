WITH latest_quarter AS (
    SELECT d_year, d_quarter_seq
    FROM (
        SELECT d_year, d_quarter_seq,
               ROW_NUMBER() OVER (ORDER BY d_year DESC, d_quarter_seq DESC) AS rn
        FROM date_dim
    ) t
    WHERE rn = 1
),
store_sales_agg AS (
    SELECT ss.ss_store_sk AS store_sk,
           d.d_year,
           d.d_quarter_seq,
           SUM(ss.ss_net_paid) AS total_net_paid,
           SUM(ss.ss_net_profit) AS total_profit,
           COUNT(DISTINCT ss.ss_ticket_number) AS txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN latest_quarter lq ON d.d_year = lq.d_year AND d.d_quarter_seq = lq.d_quarter_seq
    GROUP BY ss.ss_store_sk, d.d_year, d.d_quarter_seq
),
store_details AS (
    SELECT s.s_store_sk AS store_sk,
           s.s_store_name AS store_name,
           s.s_city,
           s.s_state,
           COALESCE(s.s_tax_percentage, 0) AS tax_pct,
           CASE WHEN s.s_city IS NULL OR s.s_state IS NULL THEN 'UNKNOWN_LOCATION' ELSE CONCAT(s.s_city, ', ', s.s_state) END AS location_desc
    FROM store s
),
ranked_store AS (
    SELECT sa.store_sk,
           sa.d_year,
           sa.d_quarter_seq,
           sa.total_profit,
           sd.store_name,
           sd.location_desc,
           sd.tax_pct,
           ROW_NUMBER() OVER (PARTITION BY sa.store_sk ORDER BY sa.total_profit DESC) AS profit_rank,
           SUM(sa.total_profit) OVER (PARTITION BY sa.store_sk ORDER BY sa.d_year, sa.d_quarter_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit
    FROM store_sales_agg sa
    LEFT JOIN store_details sd ON sa.store_sk = sd.store_sk
),
store_last_month_sales AS (
    SELECT ss.ss_store_sk AS store_sk,
           SUM(ss.ss_net_paid) AS month_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date >= CAST(date_trunc('month', date_add('month', -1, DATE '2024-10-01')) AS DATE)
      AND d.d_date < CAST(date_trunc('month', DATE '2024-10-01') AS DATE)
    GROUP BY ss.ss_store_sk
),
promo_effect AS (
    SELECT p.p_promo_id,
           COUNT(DISTINCT cs.cs_order_number) AS promo_txn_cnt,
           COALESCE(SUM(cs.cs_ext_sales_price), 0) AS promo_sales
    FROM promotion p
    LEFT JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY p.p_promo_id
),
all_stores AS (
    SELECT sd.store_sk,
           sd.store_name,
           COALESCE(r.profit_rank, 0) AS profit_rank,
           COALESCE(r.cum_profit, CAST(0 AS decimal(7,2))) AS cum_profit,
           COALESCE(ls.month_net_paid, CAST(0 AS decimal(7,2))) AS month_net_paid,
           COALESCE(r.total_profit, CAST(0 AS decimal(7,2))) - COALESCE(ls.month_net_paid, CAST(0 AS decimal(7,2))) AS profit_vs_last_month,
           CASE
               WHEN COALESCE(r.total_profit, CAST(0 AS decimal(7,2))) > 0
                    AND COALESCE(ls.month_net_paid, CAST(0 AS decimal(7,2))) > 0
               THEN (COALESCE(r.total_profit, CAST(0 AS decimal(7,2))) - COALESCE(ls.month_net_paid, CAST(0 AS decimal(7,2)))) / COALESCE(ls.month_net_paid, CAST(1 AS decimal(7,2))) * 100
               ELSE NULL
           END AS profit_change_pct,
           sd.location_desc,
           CASE WHEN TRY_CAST(SUBSTRING(sd.store_name, 1, 3) AS INTEGER) IS NULL THEN 'NON_NUMERIC_PREFIX' ELSE 'NUMERIC_PREFIX' END AS name_prefix_type,
           (SELECT COALESCE(pe.promo_txn_cnt, 0)
            FROM promo_effect pe
            WHERE pe.p_promo_id = CONCAT('PROMO_', CAST(sd.store_sk AS VARCHAR))) AS store_promo_txn_cnt
    FROM store_details sd
    LEFT JOIN ranked_store r ON sd.store_sk = r.store_sk AND r.profit_rank = 1
    LEFT JOIN store_last_month_sales ls ON sd.store_sk = ls.store_sk
    WHERE sd.s_city IS NOT NULL
),
final_result AS (
    SELECT *
    FROM all_stores
    WHERE profit_change_pct > 5
    UNION ALL
    SELECT sd.store_sk,
           sd.store_name,
           0 AS profit_rank,
           CAST(0 AS decimal(7,2)) AS cum_profit,
           CAST(0 AS decimal(7,2)) AS month_net_paid,
           CAST(NULL AS decimal(7,2)) AS profit_vs_last_month,
           CAST(NULL AS decimal(7,2)) AS profit_change_pct,
           sd.location_desc,
           CASE WHEN TRY_CAST(SUBSTRING(sd.store_name, 1, 3) AS INTEGER) IS NULL THEN 'NON_NUMERIC_PREFIX' ELSE 'NUMERIC_PREFIX' END AS name_prefix_type,
           0 AS store_promo_txn_cnt
    FROM store_details sd
    WHERE sd.store_sk NOT IN (SELECT store_sk FROM all_stores)
)
SELECT *
FROM final_result
ORDER BY profit_change_pct DESC NULLS LAST, profit_rank ASC
LIMIT 100

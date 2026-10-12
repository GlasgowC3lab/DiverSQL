WITH date_2000 AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_year = 2000
),
store_sales_agg AS (
    SELECT ss.ss_store_sk AS store_sk,
           COUNT(*) AS orders_cnt,
           SUM(ss.ss_net_paid_inc_tax) AS total_sales,
           SUM(ss.ss_net_profit) AS total_profit,
           AVG(ss.ss_net_profit) AS avg_profit,
           MAX(d.d_date) AS last_sale_date,
           MIN(d.d_date) AS first_sale_date
    FROM store_sales ss
    JOIN date_2000 d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_store_sk
),
store_returns_agg AS (
    SELECT sr.sr_store_sk AS store_sk,
           SUM(sr.sr_net_loss) AS total_loss,
           COUNT(*) AS returns_cnt,
           MAX(d.d_date) AS last_return_date
    FROM store_returns sr
    JOIN date_2000 d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_store_sk
),
store_combined AS (
    SELECT COALESCE(sa.store_sk, ra.store_sk) AS store_sk,
           COALESCE(sa.orders_cnt, 0) AS orders_cnt,
           COALESCE(sa.total_sales, 0) AS total_sales,
           COALESCE(sa.total_profit, 0) AS total_profit,
           COALESCE(ra.total_loss, 0) AS total_loss,
           COALESCE(ra.returns_cnt, 0) AS returns_cnt,
           GREATEST(COALESCE(sa.last_sale_date, DATE '1900-01-01'), COALESCE(ra.last_return_date, DATE '1900-01-01')) AS latest_activity_date
    FROM store_sales_agg sa
    FULL OUTER JOIN store_returns_agg ra ON sa.store_sk = ra.store_sk
),
store_metrics AS (
    SELECT s.s_store_sk AS store_sk,
           s.s_store_name,
           s.s_city,
           s.s_state,
           s.s_division_id,
           sc.total_sales,
           sc.total_profit,
           sc.total_loss,
           sc.orders_cnt,
           sc.returns_cnt,
           sc.latest_activity_date,
           CASE WHEN COALESCE(sc.total_sales,0) = 0 THEN 0 ELSE sc.total_profit / sc.total_sales END AS profit_margin,
           CASE WHEN COALESCE(sc.total_profit,0) = 0 THEN 0 ELSE sc.total_profit / NULLIF(sc.total_loss,0) END AS profit_to_loss_ratio,
           CONCAT(COALESCE(s.s_city,'UNKNOWN'), ' - ', s.s_store_name) AS city_store_label,
           (SELECT AVG(ss2.ss_net_paid_inc_tax)
            FROM store_sales ss2
            WHERE ss2.ss_store_sk = s.s_store_sk
              AND ss2.ss_sold_date_sk IN (SELECT d_date_sk FROM date_2000)
           ) AS avg_daily_sales,
           (SELECT p.p_promo_name
            FROM promotion p
            JOIN store_sales ss3 ON p.p_promo_sk = ss3.ss_promo_sk
            WHERE ss3.ss_store_sk = s.s_store_sk
              AND ss3.ss_sold_date_sk IN (SELECT d_date_sk FROM date_2000)
            ORDER BY p.p_cost DESC
            LIMIT 1) AS top_promo_name,
           ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY COALESCE(sc.total_profit,0) DESC) AS rn_state_profit,
           RANK() OVER (ORDER BY COALESCE(sc.total_sales,0) DESC) AS overall_sales_rank
    FROM store s
    LEFT JOIN store_combined sc ON s.s_store_sk = sc.store_sk
    LEFT JOIN call_center cc ON s.s_store_sk = cc.cc_call_center_sk
),
high_perf_stores AS (
    SELECT store_sk
    FROM store_metrics
    WHERE total_sales > 5000000 AND profit_margin > 0.2
),
low_perf_stores AS (
    SELECT store_sk
    FROM store_metrics
    WHERE total_sales < 1000000 AND profit_margin < 0.1
),
combined_perf AS (
    SELECT store_sk FROM high_perf_stores
    UNION ALL
    SELECT store_sk FROM low_perf_stores
),
ca_high_perf AS (
    SELECT store_sk
    FROM store_metrics
    WHERE s_state = 'CA' AND store_sk IN (SELECT store_sk FROM high_perf_stores)
),
ca_high_perf_intersect AS (
    SELECT store_sk
    FROM ca_high_perf
    INTERSECT
    SELECT store_sk FROM high_perf_stores
),
final AS (
    SELECT sm.*,
           CASE WHEN ci.store_sk IS NOT NULL THEN 'CA-High' ELSE 'Other' END AS ca_category
    FROM store_metrics sm
    LEFT JOIN ca_high_perf_intersect ci ON sm.store_sk = ci.store_sk
    WHERE sm.store_sk IN (SELECT store_sk FROM combined_perf)
      AND (COALESCE(sm.total_sales,0) > 0 OR COALESCE(sm.total_loss,0) > 0)
      AND (sm.top_promo_name IS NOT NULL OR sm.profit_to_loss_ratio > 1)
)
SELECT *
FROM final
ORDER BY overall_sales_rank
LIMIT 200

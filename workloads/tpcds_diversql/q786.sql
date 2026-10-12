WITH ss_agg AS (
   SELECT d.d_date,
          SUM(ss.ss_ext_sales_price) AS total_sales,
          SUM(ss.ss_net_profit) AS total_profit,
          COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
          COUNT(DISTINCT ss.ss_promo_sk)   AS distinct_promos,
          MIN(p.p_promo_name)               AS sample_promo_name,
          CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE regexp_like(CAST(ss.ss_ticket_number AS varchar), '^[0-9]{6}$')
   GROUP BY d.d_date
),
cr_agg AS (
   SELECT d.d_date,
          SUM(cr.cr_return_amount)    AS total_return_amount,
          SUM(cr.cr_net_loss)         AS total_return_loss,
          COUNT(DISTINCT cr.cr_reason_sk) AS distinct_return_reasons
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   GROUP BY d.d_date
)
SELECT
   COALESCE(ss.d_date, cr.d_date)                              AS activity_date,
   ss.total_sales,
   cr.total_return_amount,
   ss.distinct_customers,
   cr.distinct_return_reasons,
   ss.distinct_promos,
   ss.profit_flag,
   CASE
       WHEN ss.total_sales > 100000 THEN 'HIGH'
       WHEN ss.total_sales > 50000  THEN 'MEDIUM'
       ELSE 'LOW'
   END                                                         AS sales_category,
   regexp_extract(ss.sample_promo_name, '(\\w+)', 1)        AS promo_first_word,
   CASE
       WHEN regexp_like(ss.sample_promo_name, 'Sale') THEN 'HAS_SALE'
       ELSE 'NO_SALE'
   END                                                         AS promo_sale_flag,
   CONCAT(ss.sample_promo_name, '_', CAST(ss.distinct_promos AS varchar)) AS promo_summary
FROM ss_agg ss
FULL OUTER JOIN cr_agg cr
  ON ss.d_date = cr.d_date
WHERE (ss.total_sales IS NOT NULL AND ss.total_sales > 0)
  AND EXISTS (
      SELECT 1 FROM call_center cc
      WHERE cc.cc_manager LIKE 'A%'
        AND cc.cc_zip = '85804'
  )
ORDER BY activity_date DESC
LIMIT 100

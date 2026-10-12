WITH sales_agg AS (
   SELECT ss_store_sk,
          ss_sold_date_sk,
          ss_cdemo_sk,
          SUM(ss_ext_sales_price) AS total_sales,
          SUM(ss_quantity) AS total_qty,
          AVG(ss_ext_discount_amt) AS avg_discount
   FROM store_sales
   WHERE ss_wholesale_cost > 15.00
   GROUP BY ss_store_sk, ss_sold_date_sk, ss_cdemo_sk
),
union_data AS (
   SELECT
       s.s_store_sk AS entity_sk,
       d.d_year,
       'sales' AS source,
       sa.total_sales AS amount,
       COUNT(DISTINCT ss.ss_ticket_number) AS txn_count,
       sa.avg_discount AS avg_metric
   FROM sales_agg sa
   JOIN store s ON sa.ss_store_sk = s.s_store_sk
   JOIN date_dim d ON sa.ss_sold_date_sk = d.d_date_sk
   JOIN customer_demographics cd ON sa.ss_cdemo_sk = cd.cd_demo_sk
   JOIN store_sales ss ON ss.ss_store_sk = sa.ss_store_sk
                       AND ss.ss_sold_date_sk = sa.ss_sold_date_sk
                       AND ss.ss_cdemo_sk = sa.ss_cdemo_sk
   WHERE s.s_state = 'TN'
     AND d.d_moy = 5
     AND cd.cd_gender = 'M'
     AND sa.total_qty > 1
   GROUP BY s.s_store_sk, d.d_year, sa.total_sales, sa.avg_discount
   UNION DISTINCT
   SELECT
       wp.wp_web_page_sk AS entity_sk,
       d.d_year,
       'returns' AS source,
       SUM(wr.wr_return_amt) AS amount,
       COUNT(DISTINCT wr.wr_order_number) AS txn_count,
       AVG(wr.wr_fee) AS avg_metric
   FROM web_returns wr
   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
   WHERE wp.wp_type = 'article'
     AND d.d_weekend = 'N'
     AND cd.cd_education_status = 'College'
     AND wr.wr_fee > 20.00
   GROUP BY wp.wp_web_page_sk, d.d_year
)
SELECT
   entity_sk,
   d_year,
   source,
   SUM(amount) AS total_amount,
   SUM(txn_count) AS total_transactions,
   AVG(avg_metric) AS avg_metric_overall
FROM union_data ud
WHERE NOT EXISTS (
    SELECT 1 FROM union_data ud2
    WHERE ud2.entity_sk = ud.entity_sk
      AND ud2.d_year = ud.d_year
      AND ud2.source <> ud.source
)
GROUP BY entity_sk, d_year, source
ORDER BY total_amount DESC
LIMIT 100

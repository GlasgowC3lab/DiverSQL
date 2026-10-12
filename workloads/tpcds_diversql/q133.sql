WITH filtered_demo AS (
   SELECT cd_demo_sk,
          cd_gender,
          cd_marital_status,
          cd_credit_rating
   FROM   customer_demographics
   WHERE  regexp_like(cd_gender, '^[MF]')
     AND  cd_credit_rating LIKE 'A%'
),
catalog_keys AS (
   SELECT DISTINCT cs.cs_bill_customer_sk AS cust_sk
   FROM   catalog_sales cs
   JOIN   filtered_demo fd ON cs.cs_bill_cdemo_sk = fd.cd_demo_sk
   WHERE  cs.cs_ship_date_sk BETWEEN 2450849 AND 2450904
),
store_keys AS (
   SELECT DISTINCT ss.ss_customer_sk AS cust_sk
   FROM   store_sales ss
   JOIN   filtered_demo fd ON ss.ss_cdemo_sk = fd.cd_demo_sk
   WHERE  ss.ss_net_paid_inc_tax > 500
),
common_customers AS (
   SELECT cust_sk FROM catalog_keys
   INTERSECT
   SELECT cust_sk FROM store_keys
),
catalog_agg AS (
   SELECT cs.cs_bill_customer_sk AS cust_sk,
          SUM(cs.cs_net_paid)           AS catalog_net_paid,
          COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
   FROM   catalog_sales cs
   JOIN   common_customers cc ON cs.cs_bill_customer_sk = cc.cust_sk
   GROUP BY cs.cs_bill_customer_sk
),
store_agg AS (
   SELECT ss.ss_customer_sk AS cust_sk,
          SUM(ss.ss_net_paid)           AS store_net_paid,
          COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets
   FROM   store_sales ss
   JOIN   common_customers cc ON ss.ss_customer_sk = cc.cust_sk
   GROUP BY ss.ss_customer_sk
),
final_join AS (
   SELECT ca.cust_sk,
          ca.catalog_net_paid,
          ca.catalog_orders,
          sa.store_net_paid,
          sa.store_tickets,
          fd.cd_gender,
          fd.cd_marital_status
   FROM   catalog_agg ca
   JOIN   store_agg sa ON ca.cust_sk = sa.cust_sk
   JOIN   filtered_demo fd
          ON EXISTS (
               SELECT 1
               FROM   catalog_sales cs2
               WHERE  cs2.cs_bill_customer_sk = ca.cust_sk
                 AND  cs2.cs_bill_cdemo_sk = fd.cd_demo_sk
               LIMIT 1
             )
)
SELECT cd_gender,
       cd_marital_status,
       catalog_net_paid,
       store_net_paid,
       catalog_orders,
       store_tickets,
       (catalog_net_paid + store_net_paid)                         AS combined_paid,
       catalog_net_paid - (SELECT avg(cs_net_paid) FROM catalog_sales) AS catalog_vs_avg,
       regexp_extract(cd_gender, '(.)', 1)                         AS gender_initial
FROM   final_join
WHERE  cd_marital_status LIKE 'M%'
  AND  regexp_like(cd_gender, '^F')
ORDER BY combined_paid DESC
LIMIT 100

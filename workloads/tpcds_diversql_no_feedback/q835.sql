WITH catalog_agg AS (
   SELECT
       c.c_customer_sk,
       c.c_first_name,
       c.c_last_name,
       COUNT(cs.cs_order_number) AS catalog_orders,
       SUM(cs.cs_net_paid_inc_ship) AS catalog_net_paid,
       MIN(regexp_extract(p.p_promo_id, '^(A+)', 1)) AS promo_prefix
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE regexp_like(p.p_promo_id, '^A{8}C')
     AND p.p_purpose LIKE '%Unknown%'
   GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
store_agg AS (
   SELECT
       c.c_customer_sk,
       c.c_first_name,
       c.c_last_name,
       COUNT(ss.ss_ticket_number) AS store_orders,
       SUM(ss.ss_net_paid) AS store_net_paid,
       MIN(regexp_extract(p.p_promo_id, '([A-Z]{3})$', 1)) AS promo_suffix
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE regexp_like(p.p_promo_id, 'A{5}B')
      OR p.p_promo_id LIKE '%AAAAAA%'
   GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
intersect_keys AS (
   SELECT c_customer_sk FROM catalog_agg
   INTERSECT
   SELECT c_customer_sk FROM store_agg
)
SELECT
   ca.c_customer_sk,
   ca.c_first_name,
   ca.c_last_name,
   ca.catalog_orders,
   ca.catalog_net_paid,
   ca.promo_prefix,
   sa.store_orders,
   sa.store_net_paid,
   sa.promo_suffix,
   (ca.catalog_net_paid + sa.store_net_paid) AS total_net_paid
FROM intersect_keys ik
JOIN catalog_agg ca ON ik.c_customer_sk = ca.c_customer_sk
JOIN store_agg sa ON ik.c_customer_sk = sa.c_customer_sk
ORDER BY total_net_paid DESC
LIMIT 100

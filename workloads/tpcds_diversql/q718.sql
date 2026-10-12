WITH filtered_sales AS (
   SELECT
       ss_customer_sk,
       SUM(ss_net_paid) AS total_net_paid,
       AVG(ss_ext_discount_amt) AS avg_discount,
       COUNT(*) AS txn_cnt,
       MAX(ss_coupon_amt) AS max_coupon,
       CASE
           WHEN SUM(ss_net_paid) > 10000 THEN 'HIGH'
           WHEN SUM(ss_net_paid) > 5000 THEN 'MEDIUM'
           ELSE 'LOW'
       END AS spend_category
   FROM store_sales
   WHERE ss_coupon_amt > 100.00
     AND ss_ext_list_price BETWEEN 500 AND 5000
     AND ss_promo_sk IN (1044, 1061)
     AND ss_quantity >= 2
   GROUP BY ss_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    fs.total_net_paid,
    fs.avg_discount,
    fs.txn_cnt,
    fs.spend_category,
    (SELECT MAX(ss2.ss_net_paid)
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = c.c_customer_sk) AS max_net_paid_overall
FROM customer c
JOIN filtered_sales fs
   ON fs.ss_customer_sk = c.c_customer_sk
WHERE c.c_birth_day = 25
  AND c.c_birth_month = 7
  AND c.c_current_hdemo_sk = 122
  AND c.c_preferred_cust_flag = 'Y'
  AND c.c_customer_sk IN (
        SELECT ss_customer_sk FROM store_sales WHERE ss_coupon_amt > 1000
        INTERSECT
        SELECT ss_customer_sk FROM store_sales WHERE ss_ext_list_price > 2000
    )
  AND c.c_customer_sk NOT IN (
        SELECT ss_customer_sk FROM store_sales WHERE ss_promo_sk = 880
        EXCEPT
        SELECT ss_customer_sk FROM store_sales WHERE ss_coupon_amt > 500
    )
ORDER BY fs.total_net_paid DESC
LIMIT 100

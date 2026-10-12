WITH combined AS (
   SELECT
       cs.cs_bill_customer_sk AS customer_sk,
       p.p_promo_name       AS promo_name,
       cs.cs_ext_sales_price AS sales_amount,
       cs.cs_ext_discount_amt AS discount_amt
   FROM catalog_sales cs
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE p.p_channel_email = 'N'
     AND cs.cs_quantity > 5
     AND cs.cs_ext_discount_amt > 1000

   UNION ALL

   SELECT
       cs.cs_bill_customer_sk AS customer_sk,
       p.p_promo_name       AS promo_name,
       cs.cs_ext_sales_price AS sales_amount,
       cs.cs_ext_discount_amt AS discount_amt
   FROM catalog_sales cs
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE p.p_channel_tv = 'Y'
     AND cs.cs_quantity > 5
     AND cs.cs_ext_discount_amt <= 1000
)
SELECT
   customer_sk,
   promo_name,
   SUM(sales_amount)   AS total_sales,
   SUM(discount_amt)   AS total_discount,
   COUNT(*)            AS txn_count
FROM combined
GROUP BY GROUPING SETS (
   (customer_sk, promo_name),
   (customer_sk),
   (promo_name),
   ()
)
ORDER BY total_sales DESC
LIMIT 100

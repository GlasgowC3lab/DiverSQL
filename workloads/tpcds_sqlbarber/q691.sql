SELECT d_year,
       cd_gender,
       SUM(ss_net_paid) AS total_net_paid,
       COUNT(DISTINCT ss_customer_sk) AS distinct_customers
FROM store_sales
JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
JOIN customer_demographics ON store_sales.ss_cdemo_sk = customer_demographics.cd_demo_sk
JOIN promotion ON store_sales.ss_promo_sk = promotion.p_promo_sk
WHERE d_year = 1909
  AND promotion.p_promo_sk IN (
        SELECT p_promo_sk
        FROM promotion
        WHERE p_discount_active = 'N'
    )
GROUP BY d_year, cd_gender
HAVING SUM(ss_net_paid) > 204.16

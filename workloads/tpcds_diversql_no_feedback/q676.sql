WITH press_promos AS (
   SELECT
       p.p_promo_id AS promo_id,
       p.p_promo_name AS promo_name,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       SUM(ss.ss_net_profit) AS total_profit,
       CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
       (SELECT AVG(ss2.ss_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_promo_sk = p.p_promo_sk) AS avg_sales_price
   FROM promotion p
   JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
   WHERE p.p_channel_press = 'N'
     AND ss.ss_ext_sales_price > 5000
   GROUP BY p.p_promo_id, p.p_promo_name, p.p_promo_sk
),
email_promos AS (
   SELECT
       p.p_promo_id AS promo_id,
       p.p_promo_name AS promo_name,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       SUM(ss.ss_net_profit) AS total_profit,
       CASE WHEN SUM(ss.ss_net_profit) > 8000 THEN 'High' ELSE 'Low' END AS profit_category,
       (SELECT AVG(ss2.ss_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_promo_sk = p.p_promo_sk) AS avg_sales_price
   FROM promotion p
   JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
   WHERE p.p_channel_email = 'Y'
     AND ss.ss_ext_sales_price > 8000
   GROUP BY p.p_promo_id, p.p_promo_name, p.p_promo_sk
)
SELECT
    promo_id,
    promo_name,
    total_sales,
    total_profit,
    profit_category,
    avg_sales_price
FROM press_promos
UNION ALL
SELECT
    promo_id,
    promo_name,
    total_sales,
    total_profit,
    profit_category,
    avg_sales_price
FROM email_promos
LIMIT 100

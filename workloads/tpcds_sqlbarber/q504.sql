SELECT
    s.s_store_name,
    cd.cd_gender,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    (SELECT p2.p_promo_name FROM promotion p2 WHERE p2.p_promo_sk = 21 LIMIT 1) AS promo_name
FROM store_sales ss
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE ss.ss_sold_date_sk = try_cast(2451476 AS INTEGER)
GROUP BY s.s_store_name, cd.cd_gender
HAVING COUNT(*) > 2451415

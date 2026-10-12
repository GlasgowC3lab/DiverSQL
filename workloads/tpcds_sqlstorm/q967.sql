SELECT d.d_year,
       i.i_item_id,
       i.i_item_desc,
       i.i_brand,
       i.i_category,
       s.s_store_name,
       p.p_promo_name,
       cd.cd_gender,
       SUM(ss.ss_net_profit) AS total_profit,
       SUM(ss.ss_quantity) AS total_quantity,
       AVG(ss.ss_ext_discount_amt) AS avg_discount,
       AVG(ss.ss_ext_tax) AS avg_tax
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY d.d_year,
         i.i_item_id,
         i.i_item_desc,
         i.i_brand,
         i.i_category,
         s.s_store_name,
         p.p_promo_name,
         cd.cd_gender
ORDER BY total_profit DESC
LIMIT 200

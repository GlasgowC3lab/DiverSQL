WITH processed AS (
 SELECT
   s.s_store_sk,
   s.s_store_name AS store_name,
   i.i_item_sk,
   i.i_product_name,
   i.i_item_desc,
   i.i_color,
   i.i_brand,
   i.i_class,
   i.i_category,
   i.i_size,
   concat_ws(' | ', i.i_product_name, i.i_item_desc, i.i_color, i.i_brand) AS full_info,
   length(concat_ws(' | ', i.i_product_name, i.i_item_desc, i.i_color, i.i_brand)) AS full_info_len,
   replace(lower(i.i_product_name), ' ', '-') AS slug,
   substr(i.i_item_desc, 1, 30) AS short_desc,
   regexp_replace(i.i_item_desc, '\\s+', ' ') AS cleaned_desc,
   regexp_extract(i.i_product_name, '(\\d+)', 1) AS first_number,
   CASE WHEN regexp_like(i.i_product_name, '(?i)promo') THEN 'promo' ELSE 'regular' END AS promo_flag,
   translate(i.i_color, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') AS lower_color,
   nullif(trim(i.i_size), '') AS trimmed_size,
   row_number() OVER (PARTITION BY s.s_store_sk ORDER BY ss.ss_net_paid DESC) AS rank_in_store
 FROM store_sales ss
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 WHERE d.d_year = 2001
   AND i.i_product_name IS NOT NULL
   AND i.i_item_desc IS NOT NULL
)
SELECT
 rank_in_store,
 store_name,
 slug,
 full_info,
 full_info_len,
 short_desc,
 cleaned_desc,
 first_number,
 promo_flag,
 lower_color,
 trimmed_size
FROM processed
WHERE rank_in_store <= 10
ORDER BY store_name, rank_in_store

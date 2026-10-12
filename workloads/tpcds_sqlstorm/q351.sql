WITH cs_agg AS (
 SELECT cs_item_sk AS i_item_sk, sum(cs_net_paid) AS cs_total_sales
 FROM catalog_sales
 GROUP BY cs_item_sk
),
ws_agg AS (
 SELECT ws_item_sk AS i_item_sk, sum(ws_net_paid) AS ws_total_sales
 FROM web_sales
 GROUP BY ws_item_sk
),
ss_agg AS (
 SELECT ss_item_sk AS i_item_sk, sum(ss_net_paid) AS ss_total_sales
 FROM store_sales
 GROUP BY ss_item_sk
),
item_sales AS (
 SELECT i.i_item_sk,
        i.i_product_name,
        i.i_item_desc,
        i.i_category,
        coalesce(c.cs_total_sales, 0) AS cs_sales,
        coalesce(w.ws_total_sales, 0) AS ws_sales,
        coalesce(s.ss_total_sales, 0) AS ss_sales,
        coalesce(c.cs_total_sales, 0) + coalesce(w.ws_total_sales, 0) + coalesce(s.ss_total_sales, 0) AS total_sales
 FROM item i
 LEFT JOIN cs_agg c ON c.i_item_sk = i.i_item_sk
 LEFT JOIN ws_agg w ON w.i_item_sk = i.i_item_sk
 LEFT JOIN ss_agg s ON s.i_item_sk = i.i_item_sk
),
normalized_strings AS (
 SELECT i_sales.i_item_sk,
        i_sales.i_product_name,
        i_sales.i_item_desc,
        i_sales.i_category,
        lower(regexp_replace(i_sales.i_product_name, '[^A-Za-z0-9]', '')) AS product_name_norm,
        lower(regexp_replace(i_sales.i_item_desc, '[^A-Za-z0-9]', '')) AS item_desc_norm,
        length(i_sales.i_product_name) AS product_name_len,
        length(i_sales.i_item_desc) AS item_desc_len,
        cardinality(split(i_sales.i_item_desc, ' ')) AS desc_word_count,
        i_sales.cs_sales,
        i_sales.ws_sales,
        i_sales.ss_sales,
        i_sales.total_sales
 FROM item_sales i_sales
),
ranked_items AS (
 SELECT n.*,
        row_number() OVER (ORDER BY total_sales DESC) AS sales_rank,
        row_number() OVER (ORDER BY product_name_len DESC) AS name_len_rank,
        row_number() OVER (ORDER BY desc_word_count DESC) AS desc_word_rank,
        concat('Item_', CAST(n.i_item_sk AS varchar), '_', n.product_name_norm) AS composite_key,
        regexp_replace(regexp_replace(n.i_product_name, '(\\w)\\w*', '\\1'), '\\s+', '') AS initials,
        array_join(array_agg(n.product_name_norm) OVER (PARTITION BY n.i_category), ',') AS category_product_names,
        cardinality(array_agg(n.product_name_norm) OVER (PARTITION BY n.i_category)) AS category_item_count
 FROM normalized_strings n
)
SELECT r.composite_key,
       r.i_product_name,
       r.product_name_len,
       r.item_desc_len,
       r.desc_word_count,
       r.total_sales,
       r.sales_rank,
       r.name_len_rank,
       r.desc_word_rank,
       r.category_item_count,
       r.category_product_names,
       CASE
         WHEN r.total_sales > 100000 THEN 'HIGH'
         WHEN r.total_sales > 50000 THEN 'MEDIUM'
         ELSE 'LOW'
       END AS sales_bucket,
       r.initials
FROM ranked_items r
WHERE r.sales_rank <= 100
ORDER BY r.sales_rank

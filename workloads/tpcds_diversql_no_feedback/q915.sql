WITH item_words AS (
    SELECT i.i_item_sk,
           t.word
    FROM   tpcds.item i
    CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
),
filtered_items AS (
    SELECT i.i_item_sk,
           i.i_brand,
           i.i_product_name,
           i.i_current_price,
           i.i_item_desc,
           concat(i.i_brand, ' - ', i.i_product_name) AS brand_product,
           regexp_extract(i.i_item_desc, '(\\w+)', 1) AS first_word
    FROM   tpcds.item i
    WHERE  regexp_like(i.i_item_desc, '(?i)blue')               -- description mentions "blue" (case‑insensitive)
       AND i.i_product_name LIKE '%Deluxe%'
)
SELECT   w.w_warehouse_id,
         w.w_city,
         f.brand_product,
         COUNT(DISTINCT ss.ss_ticket_number) AS orders,
         SUM(ss.ss_quantity) AS total_quantity,
         SUM(ss.ss_ext_sales_price) AS total_sales,
         SUM(ss.ss_net_profit) AS total_profit,
         COUNT(DISTINCT dw.word) FILTER (WHERE regexp_like(dw.word, '^[A-Z][a-z]+$')) AS capitalized_word_cnt,
         MIN(dw.word) AS example_word
FROM     tpcds.inventory inv
JOIN     tpcds.warehouse w
         ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN     filtered_items f
         ON inv.inv_item_sk = f.i_item_sk
JOIN     tpcds.store_sales ss
         ON ss.ss_item_sk = f.i_item_sk
LEFT JOIN item_words dw
         ON dw.i_item_sk = f.i_item_sk
GROUP BY w.w_warehouse_id,
         w.w_city,
         f.brand_product
ORDER BY total_sales DESC
LIMIT 100

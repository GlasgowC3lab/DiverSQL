SELECT i.i_brand,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       SUM(ss.ss_quantity)      AS total_quantity
FROM   tpcds.store_sales ss
JOIN   tpcds.item i
       ON ss.ss_item_sk = i.i_item_sk
WHERE  i.i_brand_id = 5003002
  AND  i.i_rec_end_date = DATE '2000-10-26'
GROUP BY i.i_brand

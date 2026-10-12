WITH ss_combined AS (
   SELECT 
      ss.ss_store_sk AS store_sk,
      ss.ss_item_sk AS item_sk,
      ss.ss_ext_sales_price AS sales_price,
      td.t_hour,
      p.p_promo_name AS promo,
      lt.max_discount
   FROM store_sales ss
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   FULL OUTER JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
   CROSS JOIN LATERAL (
      SELECT max(cs.cs_ext_discount_amt) AS max_discount
      FROM catalog_sales cs
      WHERE cs.cs_item_sk = ss.ss_item_sk
   ) lt
   WHERE td.t_shift = 'first'
),
cs_data AS (
   SELECT 
      cs.cs_bill_customer_sk AS cust_sk,
      cs.cs_ext_sales_price AS sales_price,
      td.t_hour,
      cc.cc_name AS promo,
      cs.cs_quantity
   FROM catalog_sales cs
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   WHERE td.t_shift = 'second'
)
SELECT *
FROM (
   SELECT store_sk, item_sk, sales_price, t_hour, promo, max_discount
   FROM ss_combined
   UNION
   SELECT cust_sk AS store_sk, NULL AS item_sk, sales_price, t_hour, promo, NULL AS max_discount
   FROM cs_data
) u
WHERE EXISTS (SELECT 1 FROM store s WHERE s.s_store_sk = u.store_sk)
EXCEPT
SELECT store_sk, item_sk, sales_price, t_hour, promo, max_discount
FROM ss_combined
WHERE sales_price < 1000
ORDER BY sales_price DESC
OFFSET 10
LIMIT 100

WITH filtered_sales AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_sold_time_sk,
       cs.cs_item_sk,
       cs.cs_quantity,
       cs.cs_ext_sales_price,
       cs.cs_sales_price,
       cs.cs_bill_addr_sk,
       cs.cs_bill_hdemo_sk
   FROM catalog_sales cs
   WHERE cs.cs_quantity > 5
     AND cs.cs_sales_price BETWEEN 20 AND 200
     AND cs.cs_ext_sales_price > 1000
),

lateral_max AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_sold_time_sk,
       cs.cs_item_sk,
       cs.cs_quantity,
       cs.cs_ext_sales_price,
       cs.cs_sales_price,
       cs.cs_bill_addr_sk,
       cs.cs_bill_hdemo_sk,
       lm.max_price
   FROM filtered_sales cs
   CROSS JOIN LATERAL (
       SELECT MAX(cs2.cs_sales_price) AS max_price
       FROM catalog_sales cs2
       WHERE cs2.cs_item_sk = cs.cs_item_sk
         AND cs2.cs_sold_date_sk = cs.cs_sold_date_sk
   ) lm
),

joined AS (
   SELECT
       lm.cs_sold_date_sk,
       lm.cs_sold_time_sk,
       lm.cs_item_sk,
       lm.cs_quantity,
       lm.cs_ext_sales_price,
       lm.cs_sales_price,
       lm.max_price,
       ca.ca_state,
       hd.hd_buy_potential,
       i.i_category,
       i.i_class,
       t.t_hour
   FROM lateral_max lm
   JOIN customer_address ca ON lm.cs_bill_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd ON lm.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN item i ON lm.cs_item_sk = i.i_item_sk
   JOIN time_dim t ON lm.cs_sold_time_sk = t.t_time_sk
   LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
   WHERE ca.ca_state = 'CA'
     AND hd.hd_income_band_sk = 5
     AND i.i_class = 'furniture'
     AND t.t_hour BETWEEN 9 AND 17
     AND EXISTS (
         SELECT 1
         FROM web_sales ws
         WHERE ws.ws_item_sk = lm.cs_item_sk
           AND ws.ws_sold_date_sk = lm.cs_sold_date_sk
     )
)
SELECT
   i_category,
   i_class,
   ca_state,
   hd_buy_potential,
   t_hour,
   SUM(cs_ext_sales_price) AS total_sales,
   AVG(cs_sales_price) AS avg_sales_price,
   COUNT(*) AS order_count,
   MAX(max_price) AS max_individual_price
FROM joined
GROUP BY CUBE (i_category, i_class, ca_state, hd_buy_potential, t_hour)
ORDER BY total_sales DESC
LIMIT 100

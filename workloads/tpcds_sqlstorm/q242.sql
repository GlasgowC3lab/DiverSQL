WITH sales_agg AS (
   SELECT d.d_year,
          s.s_state,
          i.i_category,
          i.i_brand,
          SUM(ss.ss_net_paid) AS total_net_paid,
          SUM(ss.ss_net_profit) AS total_net_profit,
          COUNT(*) AS num_sales,
          AVG(ss.ss_quantity) AS avg_quantity,
          SUM(ss.ss_net_paid) / COUNT(DISTINCT ss.ss_customer_sk) AS avg_spent_per_customer
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE d.d_year = 2000
     AND s.s_state IN ('CA','TX','NY')
     AND i.i_category IN ('Electronics','Books','Music')
   GROUP BY d.d_year, s.s_state, i.i_category, i.i_brand
   HAVING SUM(ss.ss_net_paid) > 1000000
)
SELECT d_year,
       s_state,
       i_category,
       i_brand,
       total_net_paid,
       total_net_profit,
       num_sales,
       avg_quantity,
       avg_spent_per_customer,
       RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS sales_rank
FROM sales_agg
ORDER BY d_year, total_net_paid DESC
LIMIT 50

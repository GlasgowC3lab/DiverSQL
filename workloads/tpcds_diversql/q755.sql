WITH cs_sample AS (
   SELECT *
   FROM catalog_sales
   TABLESAMPLE BERNOULLI (10)
   WHERE cs_net_paid > 1000
),
first_part AS (
   SELECT
       cs.cs_order_number,
       cs.cs_net_paid,
       td.t_time_id,
       td.t_am_pm,
       c.c_customer_id,
       ca.ca_state,
       ss.ss_quantity,
       ss.ss_net_paid,
       sr.sr_return_amt,
       wp.wp_url,
       ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cs.cs_net_paid DESC) AS purchase_rank
   FROM cs_sample cs
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
                     AND ss.ss_sold_time_sk = td.t_time_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
   JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
   WHERE td.t_am_pm = 'PM'
     AND td.t_minute BETWEEN 10 AND 20
     AND ca.ca_country = 'USA'
     AND wp.wp_max_ad_count >= 2
     AND EXISTS (
         SELECT 1 FROM web_page wp2
         WHERE wp2.wp_customer_sk = c.c_customer_sk
           AND wp2.wp_max_ad_count > 0
     )
),
second_part AS (
   SELECT
       cs.cs_order_number,
       cs.cs_net_paid,
       td.t_time_id,
       td.t_am_pm,
       c.c_customer_id,
       ca.ca_state,
       ss.ss_quantity,
       ss.ss_net_paid,
       sr.sr_return_amt,
       wp.wp_url,
       ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cs.cs_net_paid DESC) AS purchase_rank
   FROM cs_sample cs
   JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN customer c ON cs.cs_ship_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
   JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
                     AND ss.ss_sold_time_sk = td.t_time_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
   JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
   WHERE td.t_am_pm = 'AM'
     AND td.t_minute BETWEEN 5 AND 15
     AND ca.ca_state = 'CA'
     AND wp.wp_max_ad_count <= 1
     AND EXISTS (
         SELECT 1 FROM store_returns sr2
         WHERE sr2.sr_customer_sk = c.c_customer_sk
           AND sr2.sr_return_amt > 0
     )
)
SELECT *
FROM (
   SELECT * FROM first_part
   UNION DISTINCT
   SELECT * FROM second_part
) final
ORDER BY purchase_rank, cs_net_paid DESC
LIMIT 100

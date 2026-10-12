SELECT d_year,
       country,
       category,
       SUM(net_paid) AS total_net_paid,
       SUM(quantity) AS total_quantity,
       SUM(net_profit) AS total_net_profit
FROM (
   SELECT d.d_year AS d_year,
          ca.ca_country AS country,
          i.i_category AS category,
          ss.ss_quantity AS quantity,
          ss.ss_net_paid AS net_paid,
          ss.ss_net_profit AS net_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   UNION ALL
   SELECT d.d_year,
          ca.ca_country,
          i.i_category,
          cs.cs_quantity,
          cs.cs_net_paid,
          cs.cs_net_profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   UNION ALL
   SELECT d.d_year,
          ca.ca_country,
          i.i_category,
          ws.ws_quantity,
          ws.ws_net_paid,
          ws.ws_net_profit
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
) t
WHERE d_year BETWEEN 1999 AND 2000
GROUP BY d_year, country, category
ORDER BY total_net_profit DESC
LIMIT 100

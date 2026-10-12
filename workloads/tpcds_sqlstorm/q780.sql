SELECT d.d_year,
       d.d_month_seq,
       i.i_category,
       i.i_brand,
       ca.ca_state,
       ca.ca_country,
       s.channel,
       COUNT(DISTINCT s.cust_sk) AS unique_customers,
       SUM(s.ext_sales_price) AS total_sales,
       SUM(s.net_profit) AS total_profit,
       AVG(s.ext_sales_price) AS avg_sales_per_order
FROM (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_bill_customer_sk AS cust_sk,
           cs.cs_ext_sales_price AS ext_sales_price,
           cs.cs_net_profit AS net_profit,
           'Catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_customer_sk,
           ss.ss_ext_sales_price,
           ss.ss_net_profit,
           'Store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_bill_customer_sk,
           ws.ws_ext_sales_price,
           ws.ws_net_profit,
           'Web' AS channel
    FROM web_sales ws
) s
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
JOIN customer c ON s.cust_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2000
GROUP BY d.d_year,
         d.d_month_seq,
         i.i_category,
         i.i_brand,
         ca.ca_state,
         ca.ca_country,
         s.channel
ORDER BY total_sales DESC
LIMIT 100

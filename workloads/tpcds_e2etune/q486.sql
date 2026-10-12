SELECT i.i_category,
       cd_bill.cd_gender AS bill_gender,
       cd_ship.cd_gender AS ship_gender,
       cd_current.cd_education_status AS bill_education,
       td.t_shift,
       SUM(ws.ws_net_paid) AS total_net_paid,
       SUM(ws.ws_ext_discount_amt) AS total_discount,
       COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
       AVG(ws.ws_quantity) AS avg_quantity,
       RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_net_paid) DESC) AS category_rank
FROM web_sales ws
JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer cust_bill ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer cust_ship ON ws.ws_ship_customer_sk = cust_ship.c_customer_sk
JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer_demographics cd_current ON cust_bill.c_current_cdemo_sk = cd_current.cd_demo_sk
WHERE td.t_shift IN ('Morning', 'Afternoon')
  AND i.i_category = 'Electronics'
  AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2450997
GROUP BY i.i_category,
         cd_bill.cd_gender,
         cd_ship.cd_gender,
         cd_current.cd_education_status,
         td.t_shift
HAVING SUM(ws.ws_net_paid) > 5000
ORDER BY total_net_paid DESC
LIMIT 50

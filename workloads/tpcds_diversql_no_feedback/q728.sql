WITH base1 AS (
   SELECT
       c.c_customer_sk,
       ws.ws_web_site_sk,
       SUM(ws.ws_net_paid_inc_ship_tax) AS total_paid,
       COUNT(*) AS order_cnt,
       MIN(ws.ws_net_paid_inc_ship_tax) AS min_paid,
       MAX(ws.ws_net_paid_inc_ship_tax) AS max_paid
   FROM tpcds.customer c
   JOIN tpcds.web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN tpcds.web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
   WHERE c.c_birth_day = 14
     AND ws.ws_net_paid_inc_ship_tax > 1000
     AND wsit.web_market_manager = 'James Brewer'
   GROUP BY c.c_customer_sk, ws.ws_web_site_sk
),
base2 AS (
   SELECT
       c.c_customer_sk,
       ws.ws_web_site_sk,
       SUM(ws.ws_net_paid_inc_ship_tax) AS total_paid,
       COUNT(*) AS order_cnt,
       MIN(ws.ws_net_paid_inc_ship_tax) AS min_paid,
       MAX(ws.ws_net_paid_inc_ship_tax) AS max_paid
   FROM tpcds.customer c
   JOIN tpcds.web_sales ws ON ws.ws_ship_customer_sk = c.c_customer_sk
   JOIN tpcds.web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
   WHERE c.c_birth_month = 6
     AND ws.ws_net_paid_inc_ship_tax BETWEEN 500 AND 3000
     AND wsit.web_mkt_class LIKE '%intermediat%'
   GROUP BY c.c_customer_sk, ws.ws_web_site_sk
),
union_set AS (
   SELECT * FROM base1
   UNION
   SELECT * FROM base2
),
except_set AS (
   SELECT c.c_customer_sk FROM tpcds.customer c WHERE c.c_preferred_cust_flag = 'Y'
   EXCEPT
   SELECT c.c_customer_sk FROM tpcds.customer c WHERE c.c_preferred_cust_flag = 'N'
)
SELECT
   u.c_customer_sk,
   u.ws_web_site_sk,
   u.total_paid,
   u.order_cnt,
   u.min_paid,
   u.max_paid
FROM union_set u
WHERE u.c_customer_sk IN (SELECT c.c_customer_sk FROM except_set AS c)
ORDER BY u.total_paid DESC
LIMIT 100

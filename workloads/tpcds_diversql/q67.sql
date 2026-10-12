WITH
  preferred_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
  ),
  profitable_customers AS (
    SELECT cs.cs_bill_customer_sk AS c_customer_sk
    FROM catalog_sales cs
    WHERE cs.cs_net_profit > 0
  ),
  target_customers AS (
    SELECT c_customer_sk FROM preferred_customers
    EXCEPT
    SELECT c_customer_sk FROM profitable_customers
  ),
  small_ship_mode AS (
    SELECT sm.sm_ship_mode_sk, sm.sm_type
    FROM ship_mode sm
    WHERE sm.sm_type IN ('AIR', 'RAIL')
  ),
  grp_set AS (
    SELECT 1 AS grp UNION ALL SELECT 2 AS grp
  )
SELECT
  d_ss.d_year,
  p_ss.p_promo_name,
  sm_cs.sm_type,
  SUM(ss.ss_net_paid)                         AS total_store_net_paid,
  SUM(cs.cs_net_paid_inc_ship)                AS total_catalog_net_paid_inc_ship,
  SUM(ws.ws_net_paid)                         AS total_web_net_paid,
  COUNT(DISTINCT c_cust.c_customer_sk)        AS distinct_customers,
  COUNT(*)                                      AS total_rows
FROM
  store_sales ss
  JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
  JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
  JOIN customer c_cust ON ss.ss_customer_sk = c_cust.c_customer_sk
  JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
  JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c_cust.c_customer_sk
  JOIN customer c_cs_ship ON cs.cs_ship_customer_sk = c_cs_ship.c_customer_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
  JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
  JOIN web_sales ws ON ws.ws_bill_customer_sk = c_cust.c_customer_sk
  JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
  JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
  JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  CROSS JOIN small_ship_mode sm_small
  CROSS JOIN grp_set g
WHERE
  c_cust.c_customer_sk IN (SELECT c_customer_sk FROM target_customers)
GROUP BY CUBE (d_ss.d_year, p_ss.p_promo_name, sm_cs.sm_type)
HAVING
  SUM(ss.ss_net_paid) > 10000
ORDER BY
  total_store_net_paid DESC
LIMIT 100

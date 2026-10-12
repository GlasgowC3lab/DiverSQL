WITH
  bill_orders AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_bill_customer_sk IN (
      SELECT c.c_customer_sk
      FROM customer c
      WHERE c.c_birth_year = 1965
    )
  ),
  ship_orders AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_ship_customer_sk IN (
      SELECT c.c_customer_sk
      FROM customer c
      WHERE c.c_preferred_cust_flag = 'Y'
    )
  ),
  promo_orders AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_promo_sk IN (
      SELECT p.p_promo_sk
      FROM promotion p
      WHERE p.p_discount_active = 'Y'
    )
  ),
  common_orders AS (
    SELECT cs_order_number FROM bill_orders
    INTERSECT
    SELECT cs_order_number FROM ship_orders
  ),
  final_orders AS (
    SELECT cs_order_number FROM common_orders
    EXCEPT
    SELECT cs_order_number FROM promo_orders
  )
SELECT
  p.p_promo_id,
  w.w_state,
  s.s_store_name,
  we.web_name,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(CASE WHEN cs.cs_ext_discount_amt > 0 THEN cs.cs_ext_discount_amt ELSE 0 END) AS total_discount,
  COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
  COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
  SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS pos_profit,
  COUNT(*) FILTER (WHERE r.r_reason_desc IS NOT NULL) AS return_reason_cnt
FROM final_orders fo
JOIN catalog_sales cs               ON cs.cs_order_number = fo.cs_order_number
JOIN promotion p                    ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm                   ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w                    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c_bill                ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship                ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_bill       ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship       ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_demographics cd_bill  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship  ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN store_sales ss                 ON ss.ss_customer_sk = c_bill.c_customer_sk
JOIN store s                        ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr               ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r                       ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws                  ON ws.ws_bill_customer_sk = c_ship.c_customer_sk
JOIN web_site we                    ON ws.ws_web_site_sk = we.web_site_sk
CROSS JOIN (SELECT 1 AS dummy UNION ALL SELECT 2 UNION ALL SELECT 3) AS extra
CROSS JOIN (
  SELECT r2.r_reason_id
  FROM reason r2
  WHERE r2.r_reason_desc IS NOT NULL
  LIMIT 1
) AS rd
WHERE w.w_zip IN (
  SELECT w2.w_zip
  FROM warehouse w2
  WHERE w2.w_zip LIKE '5%'
)
GROUP BY
  p.p_promo_id,
  w.w_state,
  s.s_store_name,
  we.web_name
ORDER BY total_net_paid DESC
LIMIT 100

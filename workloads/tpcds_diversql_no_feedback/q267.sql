WITH catalog_agg AS (
  SELECT
    cs.cs_bill_customer_sk,
    cs.cs_bill_cdemo_sk,
    cs.cs_promo_sk,
    cs.cs_ship_mode_sk,
    cs.cs_sold_time_sk,
    SUM(cs.cs_net_paid) AS catalog_net_paid,
    SUM(cs.cs_ext_discount_amt) AS catalog_discount,
    COUNT(*) AS catalog_orders
  FROM catalog_sales cs
  WHERE cs.cs_quantity BETWEEN 2 AND 10
    AND cs.cs_wholesale_cost > 20
    AND cs.cs_ext_ship_cost < 1000
    AND cs.cs_net_paid > 500
  GROUP BY cs.cs_bill_customer_sk,
           cs.cs_bill_cdemo_sk,
           cs.cs_promo_sk,
           cs.cs_ship_mode_sk,
           cs.cs_sold_time_sk
),
web_agg AS (
  SELECT
    ws.ws_bill_customer_sk,
    ws.ws_bill_cdemo_sk,
    ws.ws_promo_sk,
    ws.ws_ship_mode_sk,
    ws.ws_sold_time_sk,
    SUM(ws.ws_net_paid) AS web_net_paid,
    SUM(ws.ws_ext_discount_amt) AS web_discount,
    COUNT(*) AS web_orders
  FROM web_sales ws
  WHERE ws.ws_quantity BETWEEN 1 AND 5
    AND ws.ws_wholesale_cost > 15
    AND ws.ws_net_paid > 300
  GROUP BY ws.ws_bill_customer_sk,
           ws.ws_bill_cdemo_sk,
           ws.ws_promo_sk,
           ws.ws_ship_mode_sk,
           ws.ws_sold_time_sk
)
SELECT
  cust.c_customer_id,
  cust.c_first_name,
  cust.c_last_name,
  promo.p_promo_name,
  ship.sm_type,
  time_dim.t_meal_time,
  cd.cd_gender,
  ca.catalog_net_paid,
  wa.web_net_paid,
  (ca.catalog_net_paid + wa.web_net_paid) AS total_net,
  ROW_NUMBER() OVER (ORDER BY (ca.catalog_net_paid + wa.web_net_paid) DESC) AS overall_rank,
  RANK() OVER (PARTITION BY cust.c_customer_sk ORDER BY ca.catalog_net_paid DESC) AS catalog_rank_per_customer
FROM catalog_agg ca
JOIN web_agg wa
  ON ca.cs_bill_customer_sk = wa.ws_bill_customer_sk
  AND ca.cs_promo_sk = wa.ws_promo_sk
JOIN customer cust
  ON cust.c_customer_sk = ca.cs_bill_customer_sk
JOIN promotion promo
  ON promo.p_promo_sk = ca.cs_promo_sk
JOIN ship_mode ship
  ON ship.sm_ship_mode_sk = ca.cs_ship_mode_sk
JOIN time_dim time_dim
  ON time_dim.t_time_sk = ca.cs_sold_time_sk
JOIN customer_demographics cd
  ON cd.cd_demo_sk = ca.cs_bill_cdemo_sk
WHERE promo.p_discount_active = 'N'
  AND ship.sm_type = 'AIR'
  AND time_dim.t_meal_time = 'dinner'
  AND cust.c_birth_month = 5
  AND cd.cd_gender = 'M'
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = ca.cs_bill_customer_sk
          AND cs2.cs_promo_sk = ca.cs_promo_sk
          AND cs2.cs_net_paid > ca.catalog_net_paid
      )
ORDER BY total_net DESC
LIMIT 100

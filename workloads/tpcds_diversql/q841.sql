WITH
  store_agg AS (
    SELECT
      ss.ss_customer_sk AS customer_sk,
      SUM(ss.ss_net_paid)               AS store_net_paid,
      SUM(ss.ss_net_profit)             AS store_net_profit,
      COUNT(*)                          AS store_txn_cnt,
      MAX(ss.ss_sold_date_sk)           AS last_store_date_sk
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_hour BETWEEN 9 AND 17               -- predicate 1 (working hours)
      AND ca.ca_country = 'United States'        -- predicate 2 (country)
      AND cd.cd_gender = 'M'                     -- predicate 3 (gender)
      AND hd.hd_income_band_sk >= 10             -- predicate 4 (income band)
      AND ss.ss_quantity > 1                     -- predicate 5 (quantity)
    GROUP BY ss.ss_customer_sk
  ),
  web_agg AS (
    SELECT
      ws.ws_bill_customer_sk AS customer_sk,
      SUM(ws.ws_net_paid_inc_ship)      AS web_net_paid,
      SUM(ws.ws_net_profit)             AS web_net_profit,
      COUNT(*)                          AS web_txn_cnt,
      MAX(ws.ws_sold_date_sk)           AS last_web_date_sk
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_hour BETWEEN 9 AND 17               -- predicate 1 (working hours)
      AND ca.ca_state = 'CA'                     -- predicate 2 (state)
      AND cd.cd_education_status = 'College'     -- predicate 3 (education)
      AND wp.wp_type = 'Content'                 -- predicate 4 (page type)
      AND ws.ws_quantity > 1                     -- predicate 5 (quantity)
    GROUP BY ws.ws_bill_customer_sk
  ),
  combined AS (
    SELECT
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      sa.store_net_paid,
      wa.web_net_paid,
      COALESCE(sa.store_net_paid, 0) + COALESCE(wa.web_net_paid, 0) AS total_net_paid,
      COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0) AS total_net_profit,
      CASE
        WHEN COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0) > 10000 THEN 'HIGH'
        WHEN COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0) > 5000  THEN 'MEDIUM'
        ELSE 'LOW'
      END AS profit_category,
      (
        SELECT SUM(ws2.ws_net_paid_inc_ship)
        FROM web_sales ws2
        JOIN customer_address ca2 ON ws2.ws_bill_addr_sk = ca2.ca_address_sk
        WHERE ca2.ca_state = ca.ca_state
      ) AS state_total_web_paid
    FROM customer c
    LEFT JOIN store_agg sa ON c.c_customer_sk = sa.customer_sk
    LEFT JOIN web_agg wa   ON c.c_customer_sk = wa.customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE NOT EXISTS (
      SELECT 1
      FROM store_sales ss2
      WHERE ss2.ss_customer_sk = c.c_customer_sk
        AND ss2.ss_net_profit < 0
    )
  ),
  high_profit_customers AS (
    SELECT c_customer_sk
    FROM combined
    WHERE profit_category = 'HIGH' AND total_net_paid > 20000
  ),
  above_avg_customers AS (
    SELECT c_customer_sk
    FROM combined
    WHERE store_net_paid IS NOT NULL
      AND web_net_paid IS NOT NULL
      AND (store_net_paid + web_net_paid) > (SELECT AVG(total_net_paid) FROM combined)
  ),
  intersect_customers AS (
    SELECT c_customer_sk FROM high_profit_customers
    INTERSECT
    SELECT c_customer_sk FROM above_avg_customers
  )
SELECT
  c.c_customer_sk,
  c.c_first_name,
  c.c_last_name,
  com.total_net_paid,
  com.profit_category,
  com.state_total_web_paid,
  ROW_NUMBER() OVER (PARTITION BY com.profit_category ORDER BY com.total_net_paid DESC) AS rank_in_category,
  LAG(com.total_net_paid) OVER (PARTITION BY com.profit_category ORDER BY com.total_net_paid DESC) AS prev_total_net_paid
FROM combined com
JOIN customer c ON com.c_customer_sk = c.c_customer_sk
WHERE com.c_customer_sk IN (SELECT c_customer_sk FROM intersect_customers)
ORDER BY com.total_net_paid DESC
LIMIT 100

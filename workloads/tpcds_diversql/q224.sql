WITH
  -- Store sales keys for set operations
  ss_keys AS (
    SELECT ss.ss_sold_date_sk AS d_sk,
           ss.ss_sold_time_sk AS t_sk
    FROM   store_sales ss
    WHERE  ss.ss_wholesale_cost > 30
  ),
  -- Web sales keys for set operations
  ws_keys AS (
    SELECT ws.ws_sold_date_sk AS d_sk,
           ws.ws_sold_time_sk AS t_sk
    FROM   web_sales ws
    WHERE  ws.ws_wholesale_cost > 30
  ),
  -- Keys that appear in BOTH store and web sales
  intersect_keys AS (
    SELECT d_sk, t_sk
    FROM   ss_keys
    INTERSECT
    SELECT d_sk, t_sk
    FROM   ws_keys
  ),
  -- Keys that appear in store sales but NOT in web sales
  except_keys AS (
    SELECT d_sk, t_sk
    FROM   ss_keys
    EXCEPT
    SELECT d_sk, t_sk
    FROM   ws_keys
  )
SELECT
  d.d_year,
  d.d_quarter_name,
  cc.cc_name,
  cc.cc_zip,
  SUM(ss.ss_net_paid)                         AS total_store_net_paid,
  AVG(ws.ws_net_paid)                         AS avg_web_net_paid,
  COUNT(DISTINCT ss.ss_item_sk)               AS distinct_store_items,
  COALESCE(ic.cnt, 0)                         AS intersect_key_count,
  COALESCE(ec.cnt, 0)                         AS except_key_count,
  lt.max_hour                                 AS max_store_hour
FROM
  store_sales ss
  JOIN date_dim d   ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t   ON ss.ss_sold_time_sk = t.t_time_sk
  FULL OUTER JOIN web_sales ws
    ON ss.ss_sold_date_sk = ws.ws_sold_date_sk
   AND ss.ss_sold_time_sk = ws.ws_sold_time_sk
  JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
  LEFT JOIN LATERAL (
    SELECT MAX(t2.t_hour) AS max_hour
    FROM   time_dim t2
    WHERE  t2.t_time_sk = ss.ss_sold_time_sk
  ) lt ON true
  LEFT JOIN (
    SELECT d_sk, t_sk, COUNT(*) AS cnt
    FROM   intersect_keys
    GROUP BY d_sk, t_sk
  ) ic ON ic.d_sk = ss.ss_sold_date_sk AND ic.t_sk = ss.ss_sold_time_sk
  LEFT JOIN (
    SELECT d_sk, t_sk, COUNT(*) AS cnt
    FROM   except_keys
    GROUP BY d_sk, t_sk
  ) ec ON ec.d_sk = ss.ss_sold_date_sk AND ec.t_sk = ss.ss_sold_time_sk
WHERE
  d.d_quarter_name = '1902Q2'      -- selective filter 1
  AND d.d_year = 2001               -- selective filter 2
  AND cc.cc_zip = '74136'           -- selective filter 3
GROUP BY
  d.d_year,
  d.d_quarter_name,
  cc.cc_name,
  cc.cc_zip,
  ic.cnt,
  ec.cnt,
  lt.max_hour
ORDER BY
  total_store_net_paid DESC
LIMIT 100

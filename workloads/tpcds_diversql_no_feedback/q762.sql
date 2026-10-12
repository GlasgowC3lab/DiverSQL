/*
Goal: Compare revenue and customer reach for high‑value orders shipped via major carriers across catalog and web channels, showing results by source, carrier, and their combinations using a set operation, grouping sets, a cross join with a small carrier dimension, and distinct aggregates.
*/
WITH
  catalog_agg AS (
    SELECT
      'Catalog'                                   AS source,
      cs.cs_order_number                         AS order_number,
      cs.cs_net_paid_inc_ship_tax                AS net_paid,
      cs.cs_bill_customer_sk                     AS customer_sk,
      sm.sm_carrier                              AS carrier
    FROM catalog_sales cs
    JOIN customer c      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_net_paid_inc_ship_tax > 1000
      AND sm.sm_carrier IN ('USPS', 'DHL')
  ),
  web_agg AS (
    SELECT
      'Web'                                      AS source,
      ws.ws_order_number                         AS order_number,
      ws.ws_net_paid_inc_ship_tax                AS net_paid,
      ws.ws_bill_customer_sk                     AS customer_sk,
      sm.sm_carrier                              AS carrier
    FROM web_sales ws
    JOIN customer c      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_net_paid_inc_ship_tax > 1000
      AND sm.sm_carrier IN ('USPS', 'DHL')
  ),
  combined AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM web_agg
  ),
  carrier_dim AS (
    SELECT sm_carrier AS carrier
    FROM ship_mode
    WHERE sm_carrier IN ('USPS', 'DHL')
  ),
  crossed AS (
    SELECT
      c.source,
      c.order_number,
      c.net_paid,
      c.customer_sk,
      d.carrier
    FROM combined c
    CROSS JOIN carrier_dim d
  )
SELECT
  source,
  carrier,
  COUNT(DISTINCT order_number)   AS distinct_orders,
  COUNT(DISTINCT customer_sk)    AS distinct_customers,
  SUM(net_paid)                  AS total_net_paid
FROM crossed
GROUP BY GROUPING SETS (
  (source),
  (carrier),
  (source, carrier),
  ()
)
ORDER BY total_net_paid DESC
LIMIT 100

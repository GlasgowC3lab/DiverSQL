WITH catalog_agg AS (
  SELECT
    'Catalog' AS channel,
    cc.cc_call_center_id AS entity_id,
    cc.cc_city AS city,
    cc.cc_state AS state,
    SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(*) AS transaction_cnt
  FROM catalog_sales cs
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE cc.cc_gmt_offset = -5.00
    AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451200
  GROUP BY cc.cc_call_center_id, cc.cc_city, cc.cc_state
),
store_agg AS (
  SELECT
    'Store' AS channel,
    CAST(ss.ss_store_sk AS VARCHAR) AS entity_id,
    NULL AS city,
    NULL AS state,
    SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
    AVG(ss.ss_coupon_amt) AS avg_discount,
    COUNT(*) AS transaction_cnt
  FROM store_sales ss
  JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  WHERE ss.ss_quantity > 0
    AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2451200
  GROUP BY ss.ss_store_sk
),
combined AS (
  SELECT * FROM catalog_agg
  UNION ALL
  SELECT * FROM store_agg
)
SELECT
  channel,
  entity_id,
  city,
  state,
  total_net_paid,
  avg_discount,
  transaction_cnt,
  RANK() OVER (PARTITION BY channel ORDER BY total_net_paid DESC) AS rank_within_channel
FROM combined
WHERE total_net_paid > 50000
ORDER BY channel, rank_within_channel
LIMIT 20

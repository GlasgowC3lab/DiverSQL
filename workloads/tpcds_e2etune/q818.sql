WITH sales_agg AS (
  SELECT
    ss.ss_store_sk AS store_sk,
    i.i_brand AS brand,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(ss.ss_quantity) AS total_sales_qty,
    AVG(ss.ss_ext_discount_amt) AS avg_discount_amt,
    SUM(COALESCE(p.p_cost, 0)) AS total_promo_cost
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk AND p.p_item_sk = i.i_item_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
  GROUP BY ss.ss_store_sk, i.i_brand
),
returns_total AS (
  SELECT
    sr.sr_store_sk AS store_sk,
    i.i_brand AS brand,
    SUM(sr.sr_return_amt) AS total_return_amt,
    SUM(sr.sr_return_quantity) AS total_return_qty
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE sr.sr_returned_date_sk BETWEEN 2450815 AND 2451088
  GROUP BY sr.sr_store_sk, i.i_brand
),
returns_reason AS (
  SELECT
    sr.sr_store_sk AS store_sk,
    i.i_brand AS brand,
    sr.sr_reason_sk AS reason_sk,
    SUM(sr.sr_return_quantity) AS reason_return_qty
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  WHERE sr.sr_returned_date_sk BETWEEN 2450815 AND 2451088
  GROUP BY sr.sr_store_sk, i.i_brand, sr.sr_reason_sk
),
top_reason AS (
  SELECT
    store_sk,
    brand,
    reason_sk,
    ROW_NUMBER() OVER (PARTITION BY store_sk, brand ORDER BY reason_return_qty DESC) AS rn
  FROM returns_reason
)
SELECT
  s.s_store_name,
  s.s_city,
  s.s_state,
  sa.brand,
  (sa.total_net_profit - COALESCE(rt.total_return_amt, 0)) AS net_profit_after_returns,
  sa.total_sales_qty,
  COALESCE(rt.total_return_qty, 0) AS total_return_qty,
  sa.avg_discount_amt,
  sa.total_promo_cost,
  r.r_reason_desc AS most_common_return_reason
FROM sales_agg sa
LEFT JOIN returns_total rt
  ON sa.store_sk = rt.store_sk
 AND sa.brand = rt.brand
JOIN store s
  ON sa.store_sk = s.s_store_sk
LEFT JOIN top_reason tr
  ON tr.store_sk = sa.store_sk
 AND tr.brand = sa.brand
 AND tr.rn = 1
LEFT JOIN reason r
  ON tr.reason_sk = r.r_reason_sk
ORDER BY net_profit_after_returns DESC
LIMIT 100

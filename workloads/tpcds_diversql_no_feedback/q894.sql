WITH
  sales_metrics AS (
    SELECT
      s.s_store_sk,
      s.s_store_id,
      s.s_store_name,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE regexp_like(s.s_store_name, '^Store [A-Z]{1,3}$')
    GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name
  ),
  return_metrics AS (
    SELECT
      sr.sr_store_sk,
      SUM(sr.sr_net_loss) AS total_return_loss,
      COUNT(*) AS return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_store_sk
  ),
  reason_metrics AS (
    SELECT
      sr.sr_store_sk,
      COUNT(DISTINCT regexp_extract(r.r_reason_desc, '(\\w+)', 1)) AS distinct_reason_words
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY sr.sr_store_sk
  ),
  joined_metrics AS (
    SELECT
      sm.s_store_sk,
      sm.s_store_id,
      sm.s_store_name,
      sm.total_profit,
      rm.total_return_loss,
      rmt.distinct_reason_words,
      CONCAT(sm.s_store_name, ' (', sm.s_store_id, ')') AS store_label
    FROM sales_metrics sm
    LEFT JOIN return_metrics rm ON sm.s_store_sk = rm.sr_store_sk
    LEFT JOIN reason_metrics rmt ON sm.s_store_sk = rmt.sr_store_sk
  )
(
  SELECT
    store_label,
    total_profit,
    total_return_loss
  FROM joined_metrics jm
  WHERE jm.total_profit > 10000
    AND jm.total_return_loss < 5000
    AND jm.distinct_reason_words >= 2
    AND jm.s_store_name LIKE '%Store%'
    AND jm.s_store_id NOT IN (
      SELECT s_store_id FROM store WHERE s_city LIKE 'San%'
    )
)
EXCEPT
(
  SELECT
    store_label,
    total_profit,
    total_return_loss
  FROM joined_metrics jm
  WHERE jm.s_store_name LIKE '%Test%'
    OR jm.total_profit < 5000
)
ORDER BY total_profit DESC

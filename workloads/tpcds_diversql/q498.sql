WITH
  /* Returns for fiscal year 2001 with several filters */
  returns AS (
    SELECT
      wr.wr_order_number,
      wr.wr_returned_date_sk,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      wr.wr_return_tax,
      wr.wr_return_amt_inc_tax,
      wr.wr_net_loss,
      d_ret.d_date          AS return_date,
      d_ret.d_year          AS return_year
    FROM web_returns wr
    JOIN date_dim d_ret
      ON wr.wr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND wr.wr_return_quantity > 1
      AND wr.wr_return_amt_inc_tax BETWEEN 10 AND 500
  ),

  /* Call centers with closed dates in 2001 and assorted filters */
  call_center_closed AS (
    SELECT
      cc.cc_call_center_id,
      cc.cc_mkt_id,
      cc.cc_gmt_offset,
      cc.cc_state,
      d_cc.d_date          AS closed_date,
      d_cc.d_year          AS closed_year
    FROM call_center cc
    JOIN date_dim d_cc
      ON cc.cc_closed_date_sk = d_cc.d_date_sk
    WHERE cc.cc_mkt_id IN (1, 3, 5)
      AND cc.cc_gmt_offset > 0
  ),

  /* Web sites opened in 2001 and located in California */
  web_site_open AS (
    SELECT
      ws.web_site_id,
      ws.web_state,
      ws.web_gmt_offset,
      d_ws.d_date          AS open_date,
      d_ws.d_year          AS open_year
    FROM web_site ws
    JOIN date_dim d_ws
      ON ws.web_open_date_sk = d_ws.d_date_sk
    WHERE ws.web_state = 'CA'
  ),

  /* Call‑center IDs that had returns in 2001 */
  cc_returns_2001 AS (
    SELECT DISTINCT cc.cc_call_center_id
    FROM call_center_closed cc
    JOIN returns r
      ON cc.closed_year = r.return_year
  ),

  /* Call‑center IDs that had returns in 2002 (used for EXCEPT) */
  cc_returns_2002 AS (
    SELECT DISTINCT cc.cc_call_center_id
    FROM call_center_closed cc
    JOIN (
      SELECT
        d_ret.d_year AS return_year,
        wr.wr_returned_date_sk
      FROM web_returns wr
      JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
      WHERE d_ret.d_year = 2002
    ) r2002
      ON cc.closed_year = r2002.return_year
  ),

  /* Call‑center IDs present in 2001 but NOT in 2002 */
  target_cc AS (
    SELECT cc_call_center_id
    FROM cc_returns_2001
    EXCEPT
    SELECT cc_call_center_id
    FROM cc_returns_2002
  ),

  /* Expand a map of two monetary metrics for each return row */
  returns_expanded AS (
    SELECT
      r.*,
      kv.key   AS metric_name,
      kv.value AS metric_value
    FROM (
      SELECT
        r.*,
        MAP(
          ARRAY['return_amt','return_tax'],
          ARRAY[r.wr_return_amt, r.wr_return_tax]
        ) AS metrics_map
      FROM returns r
    ) r
    CROSS JOIN UNNEST(r.metrics_map) AS kv (key, value)
  )

SELECT
  ws.web_site_id,
  cc.cc_call_center_id,
  re.wr_order_number,
  re.return_date,
  CASE WHEN re.wr_net_loss > 0 THEN 'Loss' ELSE 'Gain' END AS loss_indicator,
  re.wr_return_quantity,
  re.wr_return_amt_inc_tax,
  SUM(re.wr_return_amt_inc_tax) OVER (
    PARTITION BY ws.web_site_id
    ORDER BY re.return_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_return,
  RANK() OVER (
    PARTITION BY ws.web_site_id
    ORDER BY re.wr_return_amt_inc_tax DESC
  ) AS return_rank,
  LAG(re.wr_return_amt_inc_tax, 1) OVER (
    PARTITION BY ws.web_site_id
    ORDER BY re.return_date
  ) AS prev_return_amt,
  re.metric_name,
  re.metric_value
FROM web_site_open ws
JOIN call_center_closed cc
  ON cc.closed_year = ws.open_year
JOIN returns_expanded re
  ON re.return_year = ws.open_year
JOIN target_cc tc
  ON cc.cc_call_center_id = tc.cc_call_center_id
WHERE ws.web_gmt_offset >= 0
  AND cc.cc_state IS NOT NULL
ORDER BY ws.web_site_id, cumulative_return DESC
LIMIT 100

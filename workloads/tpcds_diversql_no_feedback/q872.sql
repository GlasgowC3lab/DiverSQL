WITH
  agg_returns AS (
    SELECT
      w.w_warehouse_id,
      w.w_county,
      w.w_state,
      hd.hd_buy_potential,
      COUNT(*) AS total_returns,
      SUM(cr.cr_net_loss) AS total_net_loss,
      AVG(cr.cr_net_loss) AS avg_net_loss
    FROM catalog_returns cr
    JOIN household_demographics hd
      ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE hd.hd_dep_count >= 5
      AND hd.hd_vehicle_count >= 1
      AND w.w_state = 'TX'
    GROUP BY w.w_warehouse_id, w.w_county, w.w_state, hd.hd_buy_potential
  ),
  high_ids AS (
    SELECT w_warehouse_id
    FROM agg_returns
    WHERE avg_net_loss > 10
  ),
  low_ids AS (
    SELECT w_warehouse_id
    FROM agg_returns
    WHERE avg_net_loss <= 5
  ),
  filtered_ids AS (
    SELECT w_warehouse_id FROM high_ids
    EXCEPT
    SELECT w_warehouse_id FROM low_ids
  )
SELECT
  ar.w_warehouse_id,
  ar.w_county,
  ar.w_state,
  ar.hd_buy_potential,
  ar.total_returns,
  ar.total_net_loss,
  ar.avg_net_loss
FROM agg_returns ar
JOIN filtered_ids f ON ar.w_warehouse_id = f.w_warehouse_id
ORDER BY ar.avg_net_loss DESC
LIMIT 100

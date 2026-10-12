WITH
  sales_agg AS (
    SELECT
      td.t_shift AS t_shift,
      sm.sm_ship_mode_id AS ship_mode_id,
      'sales' AS metric_type,
      SUM(cs.cs_net_paid) AS total_amount,
      SUM(cs.cs_net_profit) AS total_profit_loss,
      CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS flag
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY CUBE (td.t_shift, sm.sm_ship_mode_id)
  ),
  returns_agg AS (
    SELECT
      td.t_shift AS t_shift,
      sm.sm_ship_mode_id AS ship_mode_id,
      'returns' AS metric_type,
      SUM(cr.cr_return_amount) AS total_amount,
      -SUM(cr.cr_net_loss) AS total_profit_loss,
      CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss' ELSE 'NoLoss' END AS flag
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY CUBE (td.t_shift, sm.sm_ship_mode_id)
  ),
  combined AS (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
  )
SELECT
  c.t_shift,
  c.ship_mode_id,
  c.metric_type,
  c.total_amount,
  c.total_profit_loss,
  c.flag
FROM combined c
WHERE EXISTS (
  SELECT 1
  FROM catalog_returns cr
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE (
    c.ship_mode_id IS NULL OR sm.sm_ship_mode_id = c.ship_mode_id
  )
  AND (
    c.t_shift IS NULL OR td.t_shift = c.t_shift
  )
)
ORDER BY c.t_shift, c.ship_mode_id, c.metric_type
LIMIT 100

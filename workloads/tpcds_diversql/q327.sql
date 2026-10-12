WITH
  catalog_agg AS (
    SELECT
      sm.sm_ship_mode_id AS ship_mode_id,
      sm.sm_carrier AS carrier,
      SUM(cr.cr_net_loss) AS total_net_loss,
      COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_customers,
      CASE WHEN SUM(cr.cr_net_loss) > 10000 THEN 'HIGH' ELSE 'LOW' END AS loss_category
    FROM catalog_returns cr
    RIGHT OUTER JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cdemo
      ON cr.cr_refunded_cdemo_sk = cdemo.cd_demo_sk
    WHERE cr.cr_return_quantity > 0
    GROUP BY sm.sm_ship_mode_id, sm.sm_carrier
  ),
  store_agg AS (
    SELECT
      CAST(NULL AS varchar) AS ship_mode_id,
      CAST(NULL AS varchar) AS carrier,
      SUM(sr.sr_net_loss) AS total_net_loss,
      COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
      CASE WHEN SUM(sr.sr_net_loss) > 8000 THEN 'HIGH' ELSE 'LOW' END AS loss_category
    FROM store_returns sr
    JOIN customer_demographics cdemo
      ON sr.sr_cdemo_sk = cdemo.cd_demo_sk
    WHERE sr.sr_return_quantity > 0
  )
SELECT DISTINCT
  ship_mode_id,
  carrier,
  total_net_loss,
  distinct_customers,
  loss_category
FROM (
  SELECT * FROM catalog_agg
  UNION ALL
  SELECT * FROM store_agg
) AS combined
ORDER BY total_net_loss DESC

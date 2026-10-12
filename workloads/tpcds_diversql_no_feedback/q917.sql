WITH filtered_returns AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_returned_time_sk,
    cr.cr_item_sk,
    cr.cr_refunded_customer_sk,
    cr.cr_refunded_hdemo_sk,
    cr.cr_returning_customer_sk,
    cr.cr_returning_hdemo_sk,
    cr.cr_ship_mode_sk,
    cr.cr_warehouse_sk,
    cr.cr_reason_sk,
    cr.cr_order_number,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_return_amt_inc_tax,
    cr.cr_fee,
    cr.cr_return_ship_cost,
    cr.cr_refunded_cash,
    cr.cr_reversed_charge,
    cr.cr_store_credit,
    cr.cr_net_loss
  FROM catalog_returns cr
  WHERE cr.cr_return_amount > 500
    AND cr.cr_return_quantity >= 1
    AND cr.cr_return_tax BETWEEN 0 AND 100
    AND cr.cr_fee < 50
    AND cr.cr_return_ship_cost IS NOT NULL
),

small_dim AS (
  SELECT 'A' AS grp UNION ALL SELECT 'B' AS grp
)

SELECT
  fr.cr_order_number,
  fr.cr_return_amount,
  fr.cr_return_quantity,
  r.r_reason_desc,
  sm.sm_type,
  w.w_warehouse_name,
  hd.hd_vehicle_count,
  CASE
    WHEN fr.cr_return_amount > 1000 THEN 'HIGH'
    ELSE 'NORMAL'
  END AS return_category,
  ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY fr.cr_return_amount DESC) AS rn_warehouse,
  sd.grp
FROM filtered_returns fr
JOIN catalog_sales cs
  ON fr.cr_order_number = cs.cs_order_number
JOIN household_demographics hd
  ON fr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN reason r
  ON fr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
  ON fr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON fr.cr_warehouse_sk = w.w_warehouse_sk
CROSS JOIN small_dim sd
WHERE r.r_reason_id = 'AAAAAAAABAAAAAA'
  AND sm.sm_type = 'AIR'
  AND w.w_state = 'CA'
  AND hd.hd_vehicle_count >= 0
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_order_number = fr.cr_order_number
          AND cs2.cs_net_profit > 0
      )
ORDER BY rn_warehouse ASC, return_category DESC
LIMIT 100

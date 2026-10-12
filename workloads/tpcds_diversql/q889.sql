WITH joined AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_ship_mode_sk,
        cr.cr_returned_date_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_returning_hdemo_sk,
        t.t_shift,
        t.t_minute,
        hd_ref.hd_dep_count,
        hd_ret.hd_vehicle_count,
        sm.sm_carrier,
        sm.sm_ship_mode_id,
        sm.sm_type
    FROM catalog_returns cr
    FULL OUTER JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    LEFT JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE hd_ref.hd_dep_count > 2
      AND t.t_shift = 'second'
      AND cr.cr_return_amount > 10
),
agg1 AS (
    SELECT
        sm.sm_ship_mode_id,
        t.t_shift,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns,
        AVG(cr.cr_return_quantity) AS avg_qty
    FROM joined cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    GROUP BY sm.sm_ship_mode_id, t.t_shift
    HAVING SUM(cr.cr_return_amount) > 100
),
agg2 AS (
    SELECT
        sm.sm_ship_mode_id,
        t.t_shift,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns,
        AVG(cr.cr_return_quantity) AS avg_qty
    FROM joined cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE cr.cr_return_quantity > 1
    GROUP BY sm.sm_ship_mode_id, t.t_shift
),
union_set AS (
    SELECT sm_ship_mode_id, t_shift, total_return_amount, cnt_returns, avg_qty FROM agg1
    UNION DISTINCT
    SELECT sm_ship_mode_id, t_shift, total_return_amount, cnt_returns, avg_qty FROM agg2
),
key_set_all AS (
    SELECT sm_ship_mode_id FROM union_set
),
key_set_exclude AS (
    SELECT sm_ship_mode_id FROM union_set WHERE total_return_amount < 150
),
key_diff AS (
    SELECT sm_ship_mode_id FROM key_set_all
    EXCEPT
    SELECT sm_ship_mode_id FROM key_set_exclude
),
carrier_set AS (
    SELECT sm_ship_mode_id FROM ship_mode WHERE sm_carrier = 'UPS'
),
key_intersect AS (
    SELECT sm_ship_mode_id FROM key_set_all
    INTERSECT
    SELECT sm_ship_mode_id FROM carrier_set
)
SELECT
    us.sm_ship_mode_id,
    us.t_shift,
    us.total_return_amount,
    us.cnt_returns,
    us.avg_qty
FROM union_set us
WHERE us.total_return_amount > (SELECT AVG(total_return_amount) FROM union_set)
  AND us.sm_ship_mode_id IN (SELECT sm_ship_mode_id FROM key_intersect)
  AND us.sm_ship_mode_id IN (SELECT sm_ship_mode_id FROM key_diff)
ORDER BY us.total_return_amount DESC
LIMIT 100

WITH inv_agg AS (
    SELECT
        inv_date_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
      AND inv_warehouse_sk IN (15, 7, 11)
    GROUP BY inv_date_sk, inv_warehouse_sk
),
joined_data AS (
    SELECT
        cc.cc_call_center_id,
        d.d_year,
        i.inv_warehouse_sk,
        SUM(wr.wr_net_loss) AS sum_net_loss,
        SUM(wr.wr_return_quantity) AS sum_return_qty,
        AVG(i.total_qty_on_hand) AS avg_qty_on_hand
    FROM web_returns wr
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
      ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd_ref
      ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret
      ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN call_center cc
      ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN inv_agg i
      ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_week_seq = 15
      AND d.d_current_quarter = 'Y'
      AND cc.cc_country = 'United States'
      AND cc.cc_city = 'Pine Ridge'
      AND t.t_hour BETWEEN 9 AND 17
      AND hd_ref.hd_vehicle_count >= 1
      AND wr.wr_return_amt > 100
    GROUP BY cc.cc_call_center_id, d.d_year, i.inv_warehouse_sk
),
filtered AS (
    SELECT
        cc_call_center_id,
        d_year,
        inv_warehouse_sk,
        sum_net_loss,
        sum_return_qty,
        avg_qty_on_hand
    FROM joined_data
    WHERE sum_net_loss > 1000
      AND sum_return_qty >= 10
)
SELECT cc_call_center_id
FROM (
    SELECT cc_call_center_id FROM filtered
) AS a
EXCEPT
SELECT cc_call_center_id
FROM (
    SELECT cc_call_center_id FROM filtered WHERE avg_qty_on_hand < 500
) AS b
ORDER BY cc_call_center_id

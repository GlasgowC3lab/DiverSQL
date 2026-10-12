WITH ws_agg AS (
    SELECT
        ws_item_sk,
        ws_ship_mode_sk,
        ws_warehouse_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_qty
    FROM web_sales
    WHERE ws_ship_customer_sk IN (8186677, 7244747, 8112527)
      AND ws_bill_hdemo_sk IN (401, 351, 1090)
      AND ws_sold_date_sk BETWEEN 2450000 AND 2450200
    GROUP BY ws_item_sk, ws_ship_mode_sk, ws_warehouse_sk
),
joined AS (
    SELECT
        ws_agg.ws_item_sk,
        ws_agg.ws_ship_mode_sk,
        ws_agg.ws_warehouse_sk,
        ws_agg.total_sales,
        ws_agg.total_qty,
        i.i_item_id,
        i.i_brand,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        w.w_warehouse_name,
        cr.cr_order_number,
        cr.cr_net_loss,
        c.c_customer_id,
        hd.hd_income_band_sk
    FROM ws_agg
    JOIN item i
        ON ws_agg.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE sm.sm_carrier = 'DHL'
      AND w.w_state = 'CA'
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450200
)
SELECT
    j.w_warehouse_name,
    j.sm_ship_mode_id,
    j.c_customer_id,
    j.i_brand,
    j.total_sales,
    j.total_qty,
    t.metric,
    t.metric_position
FROM (
    SELECT
        j.*,
        ARRAY[CAST(j.total_qty AS double), CAST(j.total_sales AS double)] AS metrics_array,
        SUM(j.cr_net_loss) OVER (PARTITION BY j.w_warehouse_name, j.sm_ship_mode_id) AS warehouse_shipmode_net_loss
    FROM joined j
) j
CROSS JOIN UNNEST(j.metrics_array) WITH ORDINALITY AS t(metric, metric_position)
WHERE j.warehouse_shipmode_net_loss > 1000
ORDER BY j.w_warehouse_name, j.sm_ship_mode_id, t.metric_position

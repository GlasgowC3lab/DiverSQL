WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        wsit.web_name,
        sm.sm_ship_mode_id,
        t.t_hour,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND wsit.web_tax_percentage > 0.05
    GROUP BY ws.ws_web_site_sk, wsit.web_name, sm.sm_ship_mode_id, t.t_hour
),
returns_agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_class,
        sm.sm_ship_mode_id,
        t.t_hour,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND cc.cc_class = 'large'
    GROUP BY cc.cc_call_center_id, cc.cc_class, sm.sm_ship_mode_id, t.t_hour
)
SELECT
    sa.web_name,
    ra.cc_call_center_id,
    sa.sm_ship_mode_id,
    sa.t_hour,
    sa.total_sales,
    ra.total_return_loss,
    (sa.total_sales - COALESCE(ra.total_return_loss, 0)) AS net_sales_after_returns,
    sa.total_profit,
    ra.total_return_qty
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.sm_ship_mode_id = ra.sm_ship_mode_id
   AND sa.t_hour = ra.t_hour
ORDER BY net_sales_after_returns DESC
LIMIT 100

WITH ws_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        sm.sm_ship_mode_id,
        SUM(ws.ws_net_profit) AS total_ws_profit,
        SUM(ws.ws_ext_sales_price) AS total_ws_sales,
        COUNT(*) AS ws_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY d.d_year, d.d_month_seq, sm.sm_ship_mode_id
),
wr_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        sm.sm_ship_mode_id,
        SUM(wr.wr_net_loss) AS total_wr_loss,
        COUNT(*) AS wr_returns
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY d.d_year, d.d_month_seq, sm.sm_ship_mode_id
),
cr_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        sm.sm_ship_mode_id,
        SUM(cr.cr_net_loss) AS total_cr_loss,
        COUNT(*) AS cr_returns
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_division_name = 'pri'
    GROUP BY d.d_year, d.d_month_seq, sm.sm_ship_mode_id
)
SELECT
    ws.d_year,
    ws.d_month_seq,
    ws.sm_ship_mode_id,
    ws.total_ws_profit,
    COALESCE(wr.total_wr_loss, 0) AS total_wr_loss,
    COALESCE(cr.total_cr_loss, 0) AS total_cr_loss,
    ws.total_ws_profit - COALESCE(wr.total_wr_loss, 0) - COALESCE(cr.total_cr_loss, 0) AS net_revenue,
    ws.ws_orders,
    COALESCE(wr.wr_returns, 0) AS wr_returns,
    COALESCE(cr.cr_returns, 0) AS cr_returns,
    RANK() OVER (ORDER BY (ws.total_ws_profit - COALESCE(wr.total_wr_loss, 0) - COALESCE(cr.total_cr_loss, 0)) DESC) AS revenue_rank
FROM ws_monthly ws
LEFT JOIN wr_monthly wr
    ON ws.d_year = wr.d_year
    AND ws.d_month_seq = wr.d_month_seq
    AND ws.sm_ship_mode_id = wr.sm_ship_mode_id
LEFT JOIN cr_monthly cr
    ON ws.d_year = cr.d_year
    AND ws.d_month_seq = cr.d_month_seq
    AND ws.sm_ship_mode_id = cr.sm_ship_mode_id
ORDER BY net_revenue DESC
LIMIT 20

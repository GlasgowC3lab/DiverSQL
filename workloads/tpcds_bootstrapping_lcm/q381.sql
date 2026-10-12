WITH aggregated AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        sm.sm_carrier,
        s.s_state,
        wp.wp_type,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS num_return_orders,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        CASE WHEN SUM(cr.cr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_severity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_quarter_name, sm.sm_carrier, s.s_state, wp.wp_type
)
SELECT
    a.d_year,
    a.d_quarter_name,
    a.sm_carrier,
    a.s_state,
    a.wp_type,
    a.total_net_loss,
    a.num_return_orders,
    a.avg_return_qty,
    a.loss_severity,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_net_loss DESC) AS loss_rank_year
FROM aggregated a
ORDER BY a.total_net_loss DESC
LIMIT 100

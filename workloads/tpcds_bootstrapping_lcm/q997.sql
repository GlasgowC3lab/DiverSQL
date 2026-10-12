WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        cc.cc_call_center_id,
        cc.cc_name AS call_center_name,
        w.w_warehouse_name,
        d_ret.d_year,
        d_ret.d_current_month,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        COUNT(*) AS num_returns,
        DATE_DIFF('day', d_cc_open.d_date, d_cc_closed.d_date) AS call_center_lifespan_days
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    CROSS JOIN store s
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    WHERE d_ret.d_year BETWEEN 2015 AND 2020
      AND s.s_state = 'CA'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        cc.cc_call_center_id,
        cc.cc_name,
        w.w_warehouse_name,
        d_ret.d_year,
        d_ret.d_current_month,
        d_cc_open.d_date,
        d_cc_closed.d_date
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.cc_call_center_id,
    a.call_center_name,
    a.w_warehouse_name,
    a.d_year,
    a.d_current_month,
    a.total_net_loss,
    a.total_return_qty,
    a.avg_return_amount,
    a.num_returns,
    a.call_center_lifespan_days,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_id, a.d_year, a.d_current_month ORDER BY a.total_net_loss DESC) AS warehouse_rank_by_loss
FROM agg a
WHERE a.total_return_qty > 0
ORDER BY a.total_net_loss DESC
LIMIT 100

WITH aggregated_returns AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name AS call_center_name,
        cc.cc_country,
        cc.cc_state,
        cc.cc_tax_percentage AS cc_tax_pct,
        d_cc_open.d_date AS cc_open_date,
        d_cc_closed.d_date AS cc_closed_date,
        date_diff('day', d_cc_open.d_date, d_cc_closed.d_date) AS cc_active_days,
        s.s_store_id,
        s.s_store_name,
        s.s_state AS store_state,
        s.s_floor_space,
        d_store_closed.d_date AS store_closed_date,
        d_ret.d_year AS return_year,
        d_ret.d_current_month AS return_month,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_country,
        cc.cc_state,
        cc.cc_tax_percentage,
        d_cc_open.d_date,
        d_cc_closed.d_date,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_floor_space,
        d_store_closed.d_date,
        d_ret.d_year,
        d_ret.d_current_month
)
SELECT
    cc_call_center_id,
    call_center_name,
    cc_country,
    cc_state,
    cc_tax_pct,
    cc_open_date,
    cc_closed_date,
    cc_active_days,
    s_store_id,
    s_store_name,
    store_state,
    s_floor_space,
    store_closed_date,
    return_year,
    return_month,
    total_return_amount,
    total_return_quantity,
    avg_return_tax,
    total_net_loss,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY return_year, cc_call_center_id ORDER BY total_return_amount DESC) AS rn_by_return
FROM aggregated_returns
WHERE total_return_amount > 1000
ORDER BY total_return_amount DESC
LIMIT 100

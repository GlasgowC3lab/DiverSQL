WITH high_value_returns AS (
    SELECT
        cr_warehouse_sk,
        cr_return_amount,
        cr_return_quantity,
        cr_returned_date_sk,
        cr_return_tax,
        cr_fee,
        cr_net_loss,
        cr_refunded_customer_sk
    FROM catalog_returns
    WHERE cr_return_amount > 1000
),
warehouse_metrics AS (
    SELECT
        cr_warehouse_sk,
        COUNT(*) AS total_returns,
        SUM(cr_return_amount) AS sum_return_amount,
        AVG(cr_return_quantity) AS avg_return_qty,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr_refunded_customer_sk) AS distinct_customers,
        SUM(CASE WHEN cr_fee > 0 THEN 1 ELSE 0 END) AS returns_with_fee
    FROM catalog_returns
    GROUP BY cr_warehouse_sk
),
high_value_agg AS (
    SELECT
        cr_warehouse_sk,
        AVG(cr_return_amount) AS avg_high_value_return_amount,
        COUNT(*) AS high_value_return_cnt
    FROM high_value_returns
    GROUP BY cr_warehouse_sk
)
SELECT
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    wm.total_returns,
    wm.sum_return_amount,
    wm.avg_return_qty,
    wm.total_net_loss,
    wm.distinct_customers,
    wm.returns_with_fee,
    ROUND(wm.returns_with_fee * 100.0 / NULLIF(wm.total_returns, 0), 2) AS pct_returns_with_fee,
    hv.avg_high_value_return_amount,
    hv.high_value_return_cnt,
    RANK() OVER (ORDER BY wm.total_net_loss DESC) AS net_loss_rank
FROM warehouse w
JOIN warehouse_metrics wm
    ON w.w_warehouse_sk = wm.cr_warehouse_sk
LEFT JOIN high_value_agg hv
    ON w.w_warehouse_sk = hv.cr_warehouse_sk
WHERE w.w_state = 'CA'
ORDER BY wm.total_net_loss DESC
LIMIT 10

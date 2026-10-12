WITH ship_mode_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        sm.sm_type,
        COUNT(*) AS returns_cnt,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_fee) AS total_fee,
        AVG(cr.cr_net_loss) AS avg_net_loss,
        SUM(cr.cr_return_quantity) AS total_quantity,
        SUM(cr.cr_store_credit) AS total_store_credit
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_store_credit > 100
      AND cr.cr_refunded_customer_sk IN (8743536, 6212854, 9240699)
      AND cr.cr_net_loss > 1000
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY sm.sm_ship_mode_id, sm.sm_carrier, sm.sm_type
    HAVING COUNT(*) >= 10
)
SELECT
    sm_ship_mode_id,
    sm_carrier,
    sm_type,
    returns_cnt,
    total_return_amount,
    total_fee,
    avg_net_loss,
    total_quantity,
    total_store_credit,
    ROUND(total_return_amount / NULLIF(total_store_credit, 0), 2) AS return_to_credit_ratio,
    RANK() OVER (ORDER BY total_return_amount DESC) AS revenue_rank
FROM ship_mode_agg
ORDER BY total_return_amount DESC
LIMIT 20

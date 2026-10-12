WITH returns_agg AS (
    SELECT
        cc.cc_name,
        cc.cc_call_center_sk,
        d.d_year,
        d.d_month_seq,
        sm.sm_type,
        COUNT(*) AS return_cnt,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_quantity
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_class = 'large'
      AND d.d_year BETWEEN 2005 AND 2007
      AND sm.sm_type IN ('Air', 'Truck')
      AND w.w_state = 'CA'
    GROUP BY
        cc.cc_name,
        cc.cc_call_center_sk,
        d.d_year,
        d.d_month_seq,
        sm.sm_type
    HAVING COUNT(*) > 50
)
SELECT
    ra.cc_name,
    ra.d_year,
    ra.d_month_seq,
    ra.sm_type,
    ra.return_cnt,
    ra.total_net_loss,
    ra.total_return_amount,
    ra.avg_quantity,
    ROUND(ra.total_net_loss / NULLIF(ra.total_return_amount, 0), 4) AS loss_ratio,
    ROW_NUMBER() OVER (PARTITION BY ra.cc_name ORDER BY ra.total_net_loss DESC) AS loss_rank
FROM returns_agg ra
ORDER BY ra.total_net_loss DESC
LIMIT 200

WITH filtered AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state,
        cr.cr_returned_date_sk,
        cr.cr_net_loss,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        cr.cr_reason_sk
    FROM tpcds.call_center AS cc
    JOIN tpcds.catalog_returns AS cr
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.household_demographics AS hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_class = 'large'
        AND cc.cc_state IN ('CA', 'NY', 'TX')
        AND cr.cr_returned_date_sk BETWEEN 2450940 AND 2450986
        AND cr.cr_reason_sk IN (6, 3, 58)
        AND hd.hd_vehicle_count >= 0
        AND hd.hd_dep_count <= 5
),
aggregated AS (
    SELECT
        cc_name,
        cc_state,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM filtered
    GROUP BY cc_name, cc_state
)
SELECT
    cc_name,
    cc_state,
    total_net_loss,
    return_cnt,
    CASE
        WHEN total_net_loss > 10000 THEN 'Very High'
        WHEN total_net_loss > 5000 THEN 'High'
        ELSE 'Medium'
    END AS loss_category,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank,
    ROW_NUMBER() OVER (PARTITION BY cc_state ORDER BY total_net_loss DESC) AS state_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100

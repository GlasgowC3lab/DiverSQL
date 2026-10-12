WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_call_center_sk,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_returning_hdemo_sk,
        cr.cr_refunded_hdemo_sk
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND cr.cr_returned_date_sk BETWEEN 20220101 AND 20221231
),
aggregate_by_cc AS (
    SELECT
        cc.cc_name,
        cc.cc_division,
        cc.cc_state,
        COUNT(*) AS total_returns,
        SUM(fr.cr_net_loss) AS total_net_loss
    FROM filtered_returns fr
    JOIN call_center cc
        ON fr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN household_demographics rd
        ON fr.cr_returning_hdemo_sk = rd.hd_demo_sk
    JOIN household_demographics rf
        ON fr.cr_refunded_hdemo_sk = rf.hd_demo_sk
    GROUP BY
        cc.cc_name,
        cc.cc_division,
        cc.cc_state
    HAVING SUM(fr.cr_net_loss) > 0
)
SELECT
    agg.cc_name,
    agg.cc_division,
    agg.cc_state,
    agg.total_returns,
    agg.total_net_loss,
    CASE
        WHEN agg.total_net_loss > 100000 THEN 'HIGH'
        WHEN agg.total_net_loss > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS net_loss_category,
    RANK() OVER (PARTITION BY agg.cc_division ORDER BY agg.total_net_loss DESC) AS division_rank
FROM aggregate_by_cc agg
ORDER BY agg.total_net_loss DESC

SELECT
    cc.cc_name,
    cc.cc_state,
    t.t_hour,
    cr.cr_returned_time_sk,
    cr.cr_net_loss,
    LAG(cr.cr_net_loss) OVER (PARTITION BY cc.cc_call_center_sk ORDER BY t.t_hour) AS prev_net_loss,
    (cr.cr_net_loss - LAG(cr.cr_net_loss) OVER (PARTITION BY cc.cc_call_center_sk ORDER BY t.t_hour)) AS net_loss_change,
    CASE
        WHEN (cr.cr_net_loss - LAG(cr.cr_net_loss) OVER (PARTITION BY cc.cc_call_center_sk ORDER BY t.t_hour)) > 0 THEN 'INCREASE'
        ELSE 'DECREASE_OR_SAME'
    END AS trend,
    CASE
        WHEN cc.cc_tax_percentage > 5 THEN 'HIGH_TAX'
        ELSE 'LOW_TAX'
    END AS tax_bracket
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
WHERE t.t_hour BETWEEN 0 AND 23
  AND cc.cc_state IS NOT NULL
ORDER BY cc.cc_name, t.t_hour

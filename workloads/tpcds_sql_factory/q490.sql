SELECT *
FROM (
    SELECT
        sm.sm_type,
        sm.sm_carrier,
        td.t_hour,
        hd_ret.hd_buy_potential,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE
            WHEN SUM(cr.cr_net_loss) > 20000 THEN 'Very High'
            WHEN SUM(cr.cr_net_loss) > 10000 THEN 'High'
            ELSE 'Moderate'
        END AS loss_category,
        RANK() OVER (ORDER BY SUM(cr.cr_net_loss) DESC) AS loss_rank
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    GROUP BY
        sm.sm_type,
        sm.sm_carrier,
        td.t_hour,
        hd_ret.hd_buy_potential
) t
WHERE t.loss_rank <= 5
ORDER BY t.loss_rank

WITH agg AS (
    SELECT
        cc.cc_class,
        cc.cc_company_name,
        r.r_reason_desc,
        hd_ref.hd_buy_potential AS refunded_buy_potential,
        hd_ret.hd_buy_potential AS returning_buy_potential,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    WHERE
        cc.cc_company_name IN ('cally', 'able')
        AND cc.cc_class = 'large'
        AND cr.cr_return_amount > 0
        AND hd_ref.hd_buy_potential = 'HIGH'
        AND hd_ret.hd_vehicle_count >= 2
    GROUP BY
        cc.cc_class,
        cc.cc_company_name,
        r.r_reason_desc,
        hd_ref.hd_buy_potential,
        hd_ret.hd_buy_potential
    HAVING SUM(cr.cr_net_loss) > 0
)
SELECT
    cc_class,
    cc_company_name,
    r_reason_desc,
    refunded_buy_potential,
    returning_buy_potential,
    total_return_amount,
    total_net_loss,
    avg_return_quantity,
    return_cnt,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY net_loss_rank
LIMIT 10

SELECT *
FROM (
    SELECT
        cr.cr_returning_customer_sk AS returning_customer_id,
        sm.sm_type,
        sm.sm_carrier,
        hd_ret.hd_buy_potential AS returning_buy_potential,
        hd_ref.hd_buy_potential AS refunded_buy_potential,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        CASE
            WHEN hd_ret.hd_buy_potential = hd_ref.hd_buy_potential THEN 'Same Potential'
            ELSE 'Different Potential'
        END AS potential_match,
        ROW_NUMBER() OVER (ORDER BY SUM(cr.cr_return_quantity) DESC) AS rn
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    GROUP BY
        cr.cr_returning_customer_sk,
        sm.sm_type,
        sm.sm_carrier,
        hd_ret.hd_buy_potential,
        hd_ref.hd_buy_potential
) ranked
WHERE ranked.rn <= 10
ORDER BY ranked.total_return_quantity DESC

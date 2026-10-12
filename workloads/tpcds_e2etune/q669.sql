WITH agg AS (
    SELECT
        hd_ret.hd_buy_potential AS returning_buy_potential,
        hd_ref.hd_buy_potential AS refunded_buy_potential,
        COUNT(*) AS num_returns,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(cr.cr_return_quantity) AS total_quantity
    FROM catalog_returns cr
    JOIN household_demographics hd_ret
        ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451016 AND 2451118
      AND cr.cr_reason_sk IN (51, 59, 62)
      AND cr.cr_returning_customer_sk IN (4103070, 9570823)
    GROUP BY hd_ret.hd_buy_potential, hd_ref.hd_buy_potential
    HAVING COUNT(*) > 5
)
SELECT
    returning_buy_potential,
    refunded_buy_potential,
    num_returns,
    total_net_loss,
    avg_return_amount,
    total_quantity,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY net_loss_rank
LIMIT 20

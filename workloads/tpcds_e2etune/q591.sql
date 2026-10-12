WITH promo_returns AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        p.p_channel_email,
        p.p_channel_dmail,
        p.p_start_date_sk,
        p.p_end_date_sk,
        sr.sr_returned_date_sk,
        sr.sr_net_loss,
        sr.sr_return_amt,
        sr.sr_return_quantity
    FROM promotion p
    JOIN store_returns sr
        ON p.p_item_sk = sr.sr_item_sk
        AND sr.sr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    WHERE (p.p_channel_email = 'Y' OR p.p_channel_dmail = 'Y')
      AND p.p_cost > 500
)
SELECT
    p_promo_id,
    p_promo_name,
    total_net_loss,
    total_return_amount,
    return_events,
    avg_return_qty,
    loss_to_cost_ratio,
    RANK() OVER (ORDER BY loss_to_cost_ratio DESC) AS loss_cost_rank
FROM (
    SELECT
        p_promo_id,
        p_promo_name,
        p_cost,
        SUM(sr_net_loss) AS total_net_loss,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_events,
        AVG(sr_return_quantity) AS avg_return_qty,
        SUM(sr_net_loss) / NULLIF(p_cost, 0) AS loss_to_cost_ratio
    FROM promo_returns
    GROUP BY p_promo_id, p_promo_name, p_cost
    HAVING SUM(sr_net_loss) > 0
) agg
ORDER BY loss_to_cost_ratio DESC
LIMIT 100

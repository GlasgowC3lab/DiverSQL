WITH agg_returns AS (
    SELECT
        cc.cc_state,
        cc.cc_name,
        p.p_promo_name,
        i.i_category,
        hd.hd_buy_potential,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_gmt_offset = -5.00
      AND p.p_start_date_sk >= 2451545
      AND cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY
        cc.cc_state,
        cc.cc_name,
        p.p_promo_name,
        i.i_category,
        hd.hd_buy_potential
)
SELECT
    cc_state,
    cc_name,
    p_promo_name,
    i_category,
    hd_buy_potential,
    total_net_loss,
    total_refunded_cash,
    total_return_amount,
    avg_return_qty,
    distinct_orders,
    RANK() OVER (PARTITION BY p_promo_name ORDER BY total_net_loss DESC) AS loss_rank
FROM agg_returns
ORDER BY total_net_loss DESC
LIMIT 100

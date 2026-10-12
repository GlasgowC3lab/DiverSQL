WITH promo_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_amt_inc_tax,
        sr.sr_net_loss,
        sr.sr_return_quantity,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        s.s_store_name,
        s.s_state,
        p.p_promo_id,
        inv.inv_quantity_on_hand
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON i.i_item_sk = p.p_item_sk
        AND sr.sr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    LEFT JOIN inventory inv
        ON sr.sr_item_sk = inv.inv_item_sk
        AND sr.sr_returned_date_sk = inv.inv_date_sk
    WHERE sr.sr_returned_date_sk BETWEEN 40000 AND 50000
), aggregated AS (
    SELECT
        s_state,
        s_store_name,
        i_brand,
        COUNT(*) AS num_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr_net_loss) AS total_net_loss,
        SUM(sr_return_quantity) AS total_quantity,
        AVG(i_current_price) AS avg_item_price,
        COUNT(DISTINCT p_promo_id) AS distinct_promos,
        AVG(inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM promo_returns
    GROUP BY s_state, s_store_name, i_brand
    HAVING SUM(sr_return_amt_inc_tax) > 1000
)
SELECT
    s_state,
    s_store_name,
    i_brand,
    num_returns,
    total_return_amount,
    total_net_loss,
    total_quantity,
    avg_item_price,
    distinct_promos,
    avg_inventory_on_hand,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_return_amount DESC) AS rank_within_state
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100

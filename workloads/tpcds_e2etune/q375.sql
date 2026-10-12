WITH catalog_agg AS (
    SELECT
        cr.cr_reason_sk,
        cr.cr_item_sk,
        cr.cr_returned_date_sk,
        cr.cr_warehouse_sk,
        SUM(cr.cr_net_loss) AS cat_net_loss,
        SUM(cr.cr_return_amt_inc_tax) AS cat_return_amt,
        SUM(cr.cr_return_quantity) AS cat_return_qty,
        COUNT(*) AS cat_return_cnt
    FROM catalog_returns cr
    WHERE cr.cr_fee > 20.0
      AND cr.cr_return_amt_inc_tax > 100.0
    GROUP BY cr.cr_reason_sk, cr.cr_item_sk, cr.cr_returned_date_sk, cr.cr_warehouse_sk
),
store_agg AS (
    SELECT
        sr.sr_reason_sk,
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_amt_inc_tax) AS store_return_amt,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    WHERE sr.sr_fee > 20.0
    GROUP BY sr.sr_reason_sk, sr.sr_item_sk, sr.sr_returned_date_sk
),
joined AS (
    SELECT
        r.r_reason_desc,
        p.p_channel_tv,
        wp.wp_type,
        ca.cr_item_sk AS item_sk,
        ca.cr_returned_date_sk AS return_date_sk,
        ca.cat_net_loss,
        sa.store_net_loss,
        ca.cat_return_amt,
        sa.store_return_amt,
        ca.cat_return_qty,
        sa.store_return_qty,
        i.inv_quantity_on_hand
    FROM catalog_agg ca
    JOIN store_agg sa
        ON ca.cr_reason_sk = sa.sr_reason_sk
       AND ca.cr_item_sk = sa.sr_item_sk
       AND ca.cr_returned_date_sk = sa.sr_returned_date_sk
    JOIN reason r
        ON ca.cr_reason_sk = r.r_reason_sk
    LEFT JOIN promotion p
        ON ca.cr_item_sk = p.p_item_sk
       AND ca.cr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    LEFT JOIN inventory i
        ON ca.cr_item_sk = i.inv_item_sk
       AND ca.cr_returned_date_sk = i.inv_date_sk
       AND ca.cr_warehouse_sk = i.inv_warehouse_sk
    LEFT JOIN web_page wp
        ON ca.cr_returned_date_sk = wp.wp_access_date_sk
    WHERE p.p_channel_tv IS NOT NULL
),
aggregated AS (
    SELECT
        r_reason_desc,
        p_channel_tv,
        wp_type,
        SUM(cat_net_loss + store_net_loss) AS total_net_loss,
        SUM(cat_return_amt + store_return_amt) AS total_return_amount,
        SUM(cat_return_qty + store_return_qty) AS total_return_quantity,
        AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
        COUNT(DISTINCT item_sk) AS distinct_items_returned
    FROM joined
    GROUP BY r_reason_desc, p_channel_tv, wp_type
)
SELECT
    r_reason_desc,
    p_channel_tv,
    wp_type,
    total_net_loss,
    total_return_amount,
    total_return_quantity,
    avg_inventory_on_hand,
    distinct_items_returned,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 20

WITH
-- Sample a fraction of the inventory table
sample_inventory AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
),

-- Store returns side with required joins and a CASE expression
store_part AS (
    SELECT
        sr.sr_item_sk               AS sr_item_sk,
        i.i_item_id                AS i_item_id,
        i.i_product_name           AS i_product_name,
        s.s_store_name             AS s_store_name,
        td.t_hour                  AS t_hour,
        r.r_reason_desc            AS r_reason_desc,
        sr.sr_return_quantity      AS sr_return_quantity,
        sr.sr_return_amt           AS sr_return_amt,
        sr.sr_net_loss             AS sr_net_loss,
        CASE WHEN sr.sr_return_quantity > 10 THEN 'High' ELSE 'Low' END AS qty_category
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN sample_inventory inv ON i.i_item_sk = inv.inv_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE sr.sr_return_quantity > 5
),

-- Catalog returns side with required joins and a CASE expression
catalog_part AS (
    SELECT
        cr.cr_item_sk               AS cr_item_sk,
        i.i_item_id                AS i_item_id,
        i.i_product_name           AS i_product_name,
        cc.cc_name                 AS cc_name,
        sm.sm_type                 AS sm_type,
        td2.t_hour                 AS t_hour,
        r2.r_reason_desc           AS r_reason_desc,
        cr.cr_return_quantity      AS cr_return_quantity,
        cr.cr_return_amount        AS cr_return_amount,
        cr.cr_net_loss             AS cr_net_loss,
        CASE WHEN cr.cr_return_quantity > 10 THEN 'High' ELSE 'Low' END AS qty_category
    FROM catalog_returns cr
    JOIN time_dim td2 ON cr.cr_returned_time_sk = td2.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
    JOIN warehouse w2 ON cr.cr_warehouse_sk = w2.w_warehouse_sk
    JOIN sample_inventory inv2 ON i.i_item_sk = inv2.inv_item_sk
    WHERE cr.cr_return_quantity > 5
),

-- Full outer join of the two sides, preserving unmatched rows
full_joined AS (
    SELECT
        COALESCE(sp.sr_item_sk, cp.cr_item_sk)                AS item_sk,
        COALESCE(sp.i_item_id, cp.i_item_id)                 AS i_item_id,
        COALESCE(sp.i_product_name, cp.i_product_name)       AS i_product_name,
        COALESCE(sp.s_store_name, cp.cc_name)               AS location_name,
        COALESCE(sp.t_hour, cp.t_hour)                       AS hour,
        COALESCE(sp.r_reason_desc, cp.r_reason_desc)         AS reason_desc,
        COALESCE(sp.sr_return_quantity, cp.cr_return_quantity) AS return_qty,
        COALESCE(sp.sr_return_amt, cp.cr_return_amount)     AS return_amount,
        COALESCE(sp.sr_net_loss, cp.cr_net_loss)             AS net_loss,
        COALESCE(sp.qty_category, cp.qty_category)           AS qty_category
    FROM store_part sp
    FULL OUTER JOIN catalog_part cp
        ON sp.sr_item_sk = cp.cr_item_sk
),

-- Union distinct of the full join result with the store side (to satisfy UNION requirement)
unioned AS (
    SELECT
        item_sk,
        i_item_id,
        i_product_name,
        location_name,
        hour,
        reason_desc,
        return_qty,
        return_amount,
        net_loss,
        qty_category
    FROM full_joined
    UNION DISTINCT
    SELECT
        sr_item_sk            AS item_sk,
        i_item_id,
        i_product_name,
        s_store_name          AS location_name,
        t_hour,
        r_reason_desc         AS reason_desc,
        sr_return_quantity    AS return_qty,
        sr_return_amt         AS return_amount,
        sr_net_loss           AS net_loss,
        qty_category
    FROM store_part
)

SELECT
    item_sk,
    i_item_id,
    i_product_name,
    location_name,
    SUM(return_amount)       AS total_return_amount,
    SUM(net_loss)            AS total_net_loss,
    COUNT(*)                 AS cnt,
    CASE WHEN SUM(return_amount) > 1000 THEN 'Very High' ELSE 'Normal' END AS amount_category
FROM unioned
GROUP BY
    item_sk,
    i_item_id,
    i_product_name,
    location_name
ORDER BY total_return_amount DESC
OFFSET 10 LIMIT 100

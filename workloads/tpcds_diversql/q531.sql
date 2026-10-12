WITH sales_item AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        i.i_item_id,
        i.i_category,
        sm.sm_carrier,
        ca.ca_state
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450836 AND 2450948               -- sold date range filter
      AND sm.sm_carrier = 'AIRBORNE'                                  -- carrier filter
      AND ca.ca_state IN ('CA', 'TX', 'NY')                           -- state filter
),

returns_combined AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        i.i_item_id,
        sm.sm_carrier AS return_ship_mode,
        ca_ref.ca_state AS refunded_state,
        ca_ret.ca_state AS returning_state
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450836 AND 2450948          -- return date range filter
      AND cr.cr_return_amount > 100.00                               -- amount filter
),

store_web_returns AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        'store' AS channel,
        ca.ca_state AS address_state
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    UNION
    SELECT
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        'web' AS channel,
        ca.ca_state AS address_state
    FROM web_returns wr
    JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
),

inventory_items AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        inv.inv_warehouse_sk,
        i.i_category,
        i.i_brand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_quantity_on_hand > 0                                 -- inventory filter
),

order_numbers_sales AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk = 2450843
),

order_numbers_returns AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk = 2450843
),

intersect_orders AS (
    SELECT cs_order_number AS order_number FROM order_numbers_sales
    INTERSECT
    SELECT cr_order_number FROM order_numbers_returns
),

store_returns_full AS (
    SELECT sr.sr_item_sk,
           sr.sr_return_quantity,
           sr.sr_return_amt,
           ca.ca_state AS store_state
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
),

web_returns_full AS (
    SELECT wr.wr_item_sk,
           wr.wr_return_quantity,
           wr.wr_return_amt,
           ca.ca_state AS web_state
    FROM web_returns wr
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
),

full_join_returns AS (
    SELECT COALESCE(s.sr_item_sk, w.wr_item_sk) AS item_sk,
           s.sr_return_quantity AS store_qty,
           w.wr_return_quantity AS web_qty,
           s.store_state,
           w.web_state
    FROM store_returns_full s
    FULL OUTER JOIN web_returns_full w
        ON s.sr_item_sk = w.wr_item_sk
)
SELECT
    si.i_item_id,
    si.i_category,
    si.sm_carrier,
    si.ca_state AS billing_state,
    si.cs_net_paid,
    rc.cr_net_loss,
    inv.inv_quantity_on_hand,
    COALESCE(fj.store_qty, 0) AS store_return_qty,
    COALESCE(fj.web_qty, 0)   AS web_return_qty,
    (
        SELECT AVG(inv2.inv_quantity_on_hand)
        FROM inventory inv2
        WHERE inv2.inv_item_sk = si.cs_item_sk
    ) AS avg_inventory_qty,
    RANK() OVER (PARTITION BY si.i_category ORDER BY rc.cr_net_loss DESC) AS loss_rank_by_category
FROM sales_item si
LEFT JOIN returns_combined rc ON si.cs_order_number = rc.cr_order_number
                               AND si.i_item_id = rc.i_item_id
LEFT JOIN inventory_items inv ON si.cs_item_sk = inv.inv_item_sk
LEFT JOIN intersect_orders io ON si.cs_order_number = io.order_number
LEFT JOIN full_join_returns fj ON si.cs_item_sk = fj.item_sk
WHERE io.order_number IS NOT NULL                                 -- ensure order appears in both sales & returns
  AND si.cs_quantity > 0                                          -- quantity filter
  AND rc.cr_net_loss IS NOT NULL                                   -- loss filter
  AND inv.inv_quantity_on_hand IS NOT NULL                         -- inventory existence filter
  AND fj.item_sk IS NOT NULL                                        -- at least one return record filter
ORDER BY loss_rank_by_category
LIMIT 100

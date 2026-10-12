WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_returning_addr_sk,
        cr.cr_warehouse_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
    WHERE NOT EXISTS (
        SELECT 1
        FROM inventory i2
        WHERE i2.inv_item_sk = cr.cr_item_sk
          AND i2.inv_date_sk = cr.cr_returned_date_sk
    )
)
SELECT
    d_ret.d_year,
    w_cr.w_warehouse_name,
    ca_ret.ca_state,
    SUM(cr.cr_return_amount)               AS total_return_amount,
    SUM(cr.cr_return_quantity)             AS total_return_quantity,
    COUNT(*)                               AS return_count,
    SUM(CASE WHEN cr.cr_net_loss > 0 THEN 1 ELSE 0 END) AS loss_count,
    SUM(CASE WHEN cr.cr_net_loss > 0 THEN cr.cr_net_loss ELSE 0 END) AS total_loss_amount,
    SUM(CASE WHEN cr.cr_net_loss <= 0 THEN cr.cr_net_loss ELSE 0 END) AS total_gain_amount
FROM filtered_returns cr
-- 1. Return date to date_dim
JOIN date_dim d_ret
  ON cr.cr_returned_date_sk = d_ret.d_date_sk
-- 2. Refunded address to customer_address (alias ca_ref)
JOIN customer_address ca_ref
  ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
-- 3. Returning address to customer_address (alias ca_ret)
JOIN customer_address ca_ret
  ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
-- 4. Return warehouse to warehouse (alias w_cr)
JOIN warehouse w_cr
  ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
-- 5. Inventory to the same return date_dim (inv‑date)
JOIN inventory inv
  ON inv.inv_date_sk = d_ret.d_date_sk
-- 6. Inventory to its own warehouse (alias w_inv)
JOIN warehouse w_inv
  ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
-- 7. Inventory also to the return warehouse (second warehouse alias w_cr2)
JOIN warehouse w_cr2
  ON inv.inv_warehouse_sk = w_cr2.w_warehouse_sk
-- 8. Web page creation date to date_dim (alias d_cre)
JOIN web_page wp
  ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN date_dim d_cre
  ON wp.wp_creation_date_sk = d_cre.d_date_sk
-- 9. Web page access date to date_dim (alias d_acc)
JOIN date_dim d_acc
  ON wp.wp_access_date_sk = d_acc.d_date_sk
GROUP BY GROUPING SETS (
    (d_ret.d_year, w_cr.w_warehouse_name, ca_ret.ca_state),
    (d_ret.d_year, w_cr.w_warehouse_name),
    (d_ret.d_year, ca_ret.ca_state),
    (w_cr.w_warehouse_name, ca_ret.ca_state),
    ()
)
ORDER BY total_return_amount DESC
LIMIT 100

WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_warehouse_sk
)
SELECT
    s.s_store_id,
    s.s_city,
    w.w_warehouse_name,
    i.i_item_id,
    r.r_reason_desc,
    SUM(ss.ss_net_profit) AS store_sales_profit,
    SUM(sr.sr_net_loss) AS store_returns_loss,
    SUM(cr.cr_net_loss) AS catalog_returns_loss,
    inv_agg.total_qty_on_hand,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inv_agg
  ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    s.s_state = 'CA'
    AND i.i_current_price > 20
    AND r.r_reason_id = 'AAAAAAAFAAAAAAA'
    AND cr.cr_return_amount > 100
    AND inv_agg.inv_warehouse_sk IN (
        SELECT w_warehouse_sk FROM warehouse WHERE w_city = 'Seattle'
    )
GROUP BY
    s.s_store_id,
    s.s_city,
    w.w_warehouse_name,
    i.i_item_id,
    r.r_reason_desc,
    inv_agg.total_qty_on_hand
HAVING
    SUM(ss.ss_net_profit) > 1000
ORDER BY
    store_sales_profit DESC
LIMIT 100

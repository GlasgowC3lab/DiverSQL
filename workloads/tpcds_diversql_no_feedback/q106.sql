WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_item_id,
    i.i_product_name,
    td.t_hour,
    ss.ss_net_paid,
    ws.ws_net_paid,
    sr.sr_net_loss,
    wr.wr_net_loss,
    inv_agg.total_qty,
    w.w_warehouse_name,
    wp.wp_url,
    r.r_reason_desc,
    CASE WHEN r.r_reason_desc LIKE '%product%' THEN 'Product Issue' ELSE 'Other' END AS reason_category,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_paid DESC) AS sales_rank
FROM item i
JOIN store_sales ss
      ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim td
      ON ss.ss_sold_time_sk = td.t_time_sk
JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
     AND sr.sr_item_sk = i.i_item_sk
LEFT JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim td_ws
      ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
     AND wr.wr_item_sk = i.i_item_sk
LEFT JOIN reason r_wr
      ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN inv_agg
      ON i.i_item_sk = inv_agg.inv_item_sk
     AND w.w_warehouse_sk = inv_agg.inv_warehouse_sk
WHERE
    i.i_category_id = 6
    AND cd.cd_credit_rating = 'Good'
    AND s.s_state = 'CA'
    AND td.t_hour BETWEEN 9 AND 17
    AND w.w_gmt_offset = -5.00
    AND inv_agg.total_qty > 10
    AND wp.wp_type = 'home'
    AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_ticket_number = ss.ss_ticket_number
          AND sr2.sr_return_quantity > 0
    )
ORDER BY sales_rank
LIMIT 100

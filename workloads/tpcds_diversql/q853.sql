WITH item_inventory AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_product_name,
        (
            SELECT SUM(inv_quantity_on_hand)
            FROM inventory inv
            WHERE inv.inv_item_sk = i.i_item_sk
        ) AS total_on_hand
    FROM item i
)
SELECT
    ii.i_category,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss' ELSE 'Profit' END AS profit_indicator,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    ii.total_on_hand
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN item_inventory ii ON ii.i_item_sk = i.i_item_sk
JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_order_number = cs.cs_order_number
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode cr_sm ON cr.cr_ship_mode_sk = cr_sm.sm_ship_mode_sk
JOIN customer_address cr_ref_addr ON cr.cr_refunded_addr_sk = cr_ref_addr.ca_address_sk
JOIN customer_address cr_ret_addr ON cr.cr_returning_addr_sk = cr_ret_addr.ca_address_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN customer_address sr_addr ON sr.sr_addr_sk = sr_addr.ca_address_sk
CROSS JOIN UNNEST(SPLIT(ca_bill.ca_city, ' ')) AS t(word)
GROUP BY ii.i_category, ii.total_on_hand
HAVING SUM(cs.cs_net_paid) > 0

UNION

SELECT
    ii.i_category,
    SUM(ws.ws_net_paid) AS total_sales,
    SUM(wr.wr_return_amt) AS total_returns,
    CASE WHEN SUM(wr.wr_net_loss) > 0 THEN 'Loss' ELSE 'Profit' END AS profit_indicator,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    ii.total_on_hand
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN item_inventory ii ON ii.i_item_sk = i.i_item_sk
JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
JOIN customer_address wr_ref_addr ON wr.wr_refunded_addr_sk = wr_ref_addr.ca_address_sk
JOIN customer_address wr_ret_addr ON wr.wr_returning_addr_sk = wr_ret_addr.ca_address_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
CROSS JOIN UNNEST(SPLIT(ca_bill.ca_city, ' ')) AS t(word)
GROUP BY ii.i_category, ii.total_on_hand
HAVING SUM(ws.ws_net_paid) > 0

LIMIT 100

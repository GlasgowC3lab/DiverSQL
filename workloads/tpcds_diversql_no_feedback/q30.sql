WITH agg_inv AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_date_sk = (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_date = DATE '2001-01-01'
    )
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    d.d_year,
    i.i_category,
    p.p_promo_name,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(agg_inv.total_qty_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT st.s_store_id) AS store_count,
    COUNT(DISTINCT ws_site.web_site_id) AS website_count
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_item_sk = i.i_item_sk
LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
LEFT JOIN agg_inv ON agg_inv.inv_item_sk = i.i_item_sk
    AND agg_inv.inv_warehouse_sk = w.w_warehouse_sk
RIGHT OUTER JOIN store st ON st.s_closed_date_sk = d.d_date_sk
WHERE p.p_promo_name = 'cally'
  AND cd.cd_gender = 'F'
  AND sm.sm_carrier = 'DHL'
GROUP BY d.d_year, i.i_category, p.p_promo_name
ORDER BY total_sales DESC
LIMIT 100

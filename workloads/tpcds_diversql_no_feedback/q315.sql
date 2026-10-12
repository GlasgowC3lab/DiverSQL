WITH inv_agg AS (
        SELECT inv_item_sk,
               inv_warehouse_sk,
               SUM(inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory
        GROUP BY inv_item_sk, inv_warehouse_sk
    ),
    avg_web_profit AS (
        SELECT AVG(ws_net_profit) AS avg_profit
        FROM web_sales
    )
SELECT
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    SUM(cs.cs_ext_sales_price)                         AS total_sales,
    SUM(cr.cr_return_amount)                           AS total_returns,
    inv_agg.total_qty_on_hand,
    CASE WHEN SUM(cs.cs_ext_sales_price) > 10000 THEN 'High' ELSE 'Low' END AS sales_category,
    ap.avg_profit
FROM item i
JOIN inv_agg
  ON i.i_item_sk = inv_agg.inv_item_sk
JOIN catalog_sales cs
  ON i.i_item_sk = cs.cs_item_sk
JOIN catalog_returns cr
  ON i.i_item_sk = cr.cr_item_sk
 AND cs.cs_order_number = cr.cr_order_number
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td_cs
  ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN customer c_bill
  ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_bill
  ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib
  ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN web_sales ws
  ON i.i_item_sk = ws.ws_item_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site web
  ON ws.ws_web_site_sk = web.web_site_sk
JOIN time_dim td_ws
  ON ws.ws_sold_time_sk = td_ws.t_time_sk
CROSS JOIN avg_web_profit ap
WHERE
    i.i_size IN ('medium', 'large')
    AND i.i_current_price > 20
    AND td_cs.t_hour BETWEEN 8 AND 18
    AND cd_bill.cd_education_status = 'College'
    AND ib.ib_upper_bound >= 50000
    AND i.i_item_sk NOT IN (
        SELECT cr2.cr_item_sk
        FROM catalog_returns cr2
        WHERE cr2.cr_return_quantity > 0
    )
GROUP BY
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    inv_agg.total_qty_on_hand,
    ap.avg_profit
HAVING
    SUM(cs.cs_ext_sales_price) > 5000
ORDER BY
    total_sales DESC
LIMIT 100

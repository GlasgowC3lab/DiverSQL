WITH
    sales AS (
        SELECT
            cs.cs_sold_date_sk,
            cs.cs_ship_date_sk,
            cs.cs_bill_cdemo_sk,
            cs.cs_bill_addr_sk,
            cs.cs_ship_cdemo_sk,
            cs.cs_ship_addr_sk,
            cs.cs_catalog_page_sk,
            cs.cs_ship_mode_sk,
            cs.cs_warehouse_sk,
            cs.cs_item_sk,
            cs.cs_promo_sk,
            cs.cs_order_number,
            cs.cs_net_profit
        FROM catalog_sales cs
    ),
    returns AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_item_sk,
            cr.cr_return_quantity,
            cr.cr_return_amount,
            cr.cr_reason_sk,
            cr.cr_order_number,
            cr.cr_catalog_page_sk,
            cr.cr_ship_mode_sk,
            cr.cr_warehouse_sk,
            cr.cr_refunded_cdemo_sk,
            cr.cr_refunded_addr_sk,
            cr.cr_returning_cdemo_sk,
            cr.cr_returning_addr_sk
        FROM catalog_returns cr
    ),
    const_vals AS (
        SELECT 1 AS grp UNION ALL SELECT 2
    )
SELECT
    r2.r_reason_desc,
    sm.sm_carrier,
    d_ret.d_year,
    SUM(s.cs_net_profit)                     AS total_sales_profit,
    SUM(r.cr_return_amount)                  AS total_return_amount,
    SUM(ws.ws_net_profit)                    AS total_web_profit,
    COUNT(DISTINCT s.cs_order_number)        AS distinct_orders,
    cv.grp
FROM sales s
JOIN date_dim d_sales
  ON s.cs_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_ret
  ON s.cs_ship_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd_bill
  ON s.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_address ca_bill
  ON s.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_ship
  ON s.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer_address ca_ship
  ON s.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN catalog_page cp_sales
  ON s.cs_catalog_page_sk = cp_sales.cp_catalog_page_sk
JOIN ship_mode sm
  ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON s.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
  ON s.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON s.cs_promo_sk = p.p_promo_sk
LEFT JOIN returns r
  ON s.cs_order_number = r.cr_order_number
 AND s.cs_item_sk = r.cr_item_sk
LEFT JOIN reason r2
  ON r.cr_reason_sk = r2.r_reason_sk
LEFT JOIN catalog_page cp_ret
  ON r.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
LEFT JOIN ship_mode sm_ret
  ON r.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
LEFT JOIN warehouse w_ret
  ON r.cr_warehouse_sk = w_ret.w_warehouse_sk
LEFT JOIN date_dim d_ret_date
  ON r.cr_returned_date_sk = d_ret_date.d_date_sk
-- Web‑sales part (star joins to the same dimensions)
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN ship_mode sm_web
  ON ws.ws_ship_mode_sk = sm_web.sm_ship_mode_sk
JOIN warehouse w_web
  ON ws.ws_warehouse_sk = w_web.w_warehouse_sk
JOIN promotion p_web
  ON ws.ws_promo_sk = p_web.p_promo_sk
JOIN date_dim d_web_sold
  ON ws.ws_sold_date_sk = d_web_sold.d_date_sk
JOIN date_dim d_web_ship
  ON ws.ws_ship_date_sk = d_web_ship.d_date_sk
CROSS JOIN const_vals cv
WHERE d_sales.d_year = 1999
GROUP BY r2.r_reason_desc, sm.sm_carrier, d_ret.d_year, cv.grp
HAVING SUM(s.cs_net_profit) > 10000
ORDER BY total_sales_profit DESC
LIMIT 100

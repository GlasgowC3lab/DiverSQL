WITH inv_agg AS (
        SELECT inv_item_sk,
               inv_warehouse_sk,
               SUM(inv_quantity_on_hand) AS total_qty,
               COUNT(*) AS cnt_days
        FROM inventory
        WHERE inv_quantity_on_hand > 300
        GROUP BY inv_item_sk, inv_warehouse_sk
    ),
    intersect_orders AS (
        SELECT cr_order_number AS order_num
        FROM catalog_returns
        WHERE cr_return_quantity > 1
        INTERSECT
        SELECT ws_order_number
        FROM web_sales
        WHERE ws_quantity > 1
    ),
    except_items AS (
        SELECT cs_item_sk AS item_sk
        FROM catalog_sales
        EXCEPT
        SELECT sr_item_sk
        FROM store_returns
    )
SELECT
    d.d_year,
    i.i_category,
    w.w_warehouse_name,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(ws.ws_net_profit) AS web_profit,
    inv_agg.total_qty,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank,
    CASE WHEN cr.cr_return_quantity > 0 THEN 'Returned' ELSE 'Sold' END AS sale_status
FROM catalog_sales cs
FULL OUTER JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN inventory inv
    ON i.i_item_sk = inv.inv_item_sk
JOIN inv_agg
    ON i.i_item_sk = inv_agg.inv_item_sk
   AND w.w_warehouse_sk = inv_agg.inv_warehouse_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_item_sk = i.i_item_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
JOIN store_returns sr
    ON i.i_item_sk = sr.sr_item_sk
   AND d.d_date_sk = sr.sr_returned_date_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
   AND sr.sr_reason_sk = r.r_reason_sk
WHERE d.d_year = 2002
  AND i.i_color = 'red'
  AND w.w_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND ca.ca_country = 'JORDAN'
  AND c.c_preferred_cust_flag = 'Y'
  AND cs.cs_item_sk IN (SELECT item_sk FROM except_items)
  AND cs.cs_order_number IN (SELECT order_num FROM intersect_orders)
GROUP BY
    d.d_year,
    i.i_category,
    w.w_warehouse_name,
    inv_agg.total_qty,
    cr.cr_return_quantity
HAVING SUM(cs.cs_net_profit) > 0
ORDER BY total_profit DESC
LIMIT 100

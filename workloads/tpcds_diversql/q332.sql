WITH inv_agg AS (
   SELECT inv_item_sk,
          inv_warehouse_sk,
          SUM(inv_quantity_on_hand) AS total_qty
   FROM inventory
   JOIN date_dim d_inv ON inventory.inv_date_sk = d_inv.d_date_sk
   WHERE d_inv.d_year = 2001
   GROUP BY inv_item_sk, inv_warehouse_sk
),
agg_a AS (
   SELECT i.i_category,
          w.w_warehouse_name,
          d.d_year,
          SUM(ws.ws_ext_sales_price)               AS web_sales_amount,
          SUM(cs.cs_ext_sales_price)               AS catalog_sales_amount,
          SUM(sr.sr_return_amt)                   AS total_returns,
          SUM(inv_agg.total_qty)                  AS inventory_on_hand,
          COUNT(DISTINCT cs.cs_order_number)      AS catalog_orders,
          COUNT(DISTINCT ws.ws_order_number)      AS web_orders
   FROM web_sales ws
   RIGHT OUTER JOIN web_site wsd
     ON ws.ws_web_site_sk = wsd.web_site_sk
   JOIN item i
     ON ws.ws_item_sk = i.i_item_sk
   JOIN date_dim d
     ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t
     ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN warehouse w
     ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN customer_address ca
     ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN catalog_sales cs
     ON cs.cs_item_sk = i.i_item_sk
    AND cs.cs_sold_date_sk = d.d_date_sk
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN store_returns sr
     ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_returned_date_sk = d.d_date_sk
   JOIN inv_agg
     ON inv_agg.inv_item_sk = i.i_item_sk
    AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year = 2001
     AND ca.ca_state = 'CA'
     AND i.i_brand = 'Brand#12'
     AND t.t_meal_time = 'lunch'
     AND w.w_state = 'CA'
     AND cc.cc_name = 'Call Center 1'
   GROUP BY GROUPING SETS (
     (i.i_category, d.d_year),
     (w.w_warehouse_name, d.d_year)
   )
),
agg_b AS (
   SELECT i.i_category,
          w.w_warehouse_name,
          d.d_year,
          SUM(ws.ws_ext_sales_price)               AS web_sales_amount,
          SUM(cs.cs_ext_sales_price)               AS catalog_sales_amount,
          SUM(sr.sr_return_amt)                   AS total_returns,
          SUM(inv_agg.total_qty)                  AS inventory_on_hand,
          COUNT(DISTINCT cs.cs_order_number)      AS catalog_orders,
          COUNT(DISTINCT ws.ws_order_number)      AS web_orders
   FROM web_sales ws
   RIGHT OUTER JOIN web_site wsd
     ON ws.ws_web_site_sk = wsd.web_site_sk
   JOIN item i
     ON ws.ws_item_sk = i.i_item_sk
   JOIN date_dim d
     ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t
     ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN warehouse w
     ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN customer_address ca
     ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN catalog_sales cs
     ON cs.cs_item_sk = i.i_item_sk
    AND cs.cs_sold_date_sk = d.d_date_sk
   JOIN call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN store_returns sr
     ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_returned_date_sk = d.d_date_sk
   JOIN inv_agg
     ON inv_agg.inv_item_sk = i.i_item_sk
    AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year = 2001
     AND ca.ca_state = 'TX'
     AND i.i_brand = 'Brand#13'
     AND t.t_meal_time = 'dinner'
     AND w.w_state = 'TX'
     AND cc.cc_name = 'Call Center 2'
   GROUP BY GROUPING SETS (
     (i.i_category, d.d_year),
     (w.w_warehouse_name, d.d_year)
   )
)
SELECT *
FROM agg_a
EXCEPT
SELECT *
FROM agg_b
ORDER BY i_category NULLS LAST,
         w_warehouse_name NULLS LAST,
         d_year
LIMIT 100

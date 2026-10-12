WITH inventory_agg AS (
    SELECT
        i.i_item_id,
        w.w_warehouse_name,
        d.d_year,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY i.i_item_id, w.w_warehouse_name, d.d_year
),
sales_agg AS (
    SELECT
        d_sold.d_year,
        i.i_class,
        i.i_class_id,
        cc.cc_state,
        cp.cp_type,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(sr.sr_net_loss) AS total_return_loss,
        inv_agg.total_qty_on_hand
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN inventory_agg inv_agg
        ON inv_agg.i_item_id = i.i_item_id
        AND inv_agg.w_warehouse_name = w.w_warehouse_name
        AND inv_agg.d_year = d_sold.d_year
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    WHERE d_sold.d_year = 2001
      AND i.i_class_id IN (5, 12)
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'monthly'
      AND sm.sm_type = 'air'
    GROUP BY
        d_sold.d_year,
        i.i_class,
        i.i_class_id,
        cc.cc_state,
        cp.cp_type,
        inv_agg.total_qty_on_hand
)
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_catalog_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY sales_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

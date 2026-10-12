WITH base AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        s.s_store_name,
        cc.cc_name,
        sm.sm_type,
        w.w_warehouse_name,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(sr.sr_return_amt) AS total_store_returns,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(cr.cr_return_amount) AS total_catalog_returns,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT cd.cd_demo_sk) AS distinct_demo_count
    FROM store_sales ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_cs_sold ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        s.s_store_name,
        cc.cc_name,
        sm.sm_type,
        w.w_warehouse_name
)
SELECT
    *,
    RANK() OVER (PARTITION BY s_store_name ORDER BY total_store_sales DESC) AS sales_rank
FROM base
WHERE total_store_sales > 0
ORDER BY total_store_sales DESC
LIMIT 100

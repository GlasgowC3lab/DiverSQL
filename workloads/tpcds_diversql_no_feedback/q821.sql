WITH ranked_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_web_page_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        d.d_date,
        d.d_year,
        t.t_hour,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        ca.ca_city,
        sm.sm_type,
        w.w_warehouse_name,
        w.w_state,
        wp.wp_web_page_id,
        -- window aggregates
        SUM(ws.ws_ext_sales_price) OVER (PARTITION BY i.i_item_id) AS total_item_sales,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY d.d_date DESC) AS rn,
        -- array for UNNEST later
        ARRAY[ws.ws_quantity, ws.ws_net_paid] AS qty_paid_arr
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                               AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                               AND inv.inv_warehouse_sk = w.w_warehouse_sk
                               AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
                               AND ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Electronics'
      AND w.w_state = 'CA'
      AND ws.ws_net_profit > 0
      AND sm.sm_type = 'AIR'
      AND t.t_hour BETWEEN 9 AND 17
),
expanded AS (
    SELECT
        rs.d_date,
        rs.i_item_id,
        rs.i_product_name,
        rs.w_warehouse_name,
        rs.sm_type,
        rs.ca_city,
        rs.ws_quantity,
        rs.ws_net_paid,
        rs.ws_net_profit,
        rs.total_item_sales,
        rs.rn,
        u.metric_value,
        u.metric_position
    FROM ranked_sales rs
    CROSS JOIN UNNEST(rs.qty_paid_arr) WITH ORDINALITY AS u(metric_value, metric_position)
    WHERE rs.rn = 1
)
SELECT
    d_date,
    i_item_id,
    i_product_name,
    w_warehouse_name,
    sm_type,
    ca_city,
    ws_quantity,
    ws_net_paid,
    ws_net_profit,
    total_item_sales,
    RANK() OVER (ORDER BY total_item_sales DESC) AS item_sales_rank,
    metric_value,
    metric_position
FROM expanded
ORDER BY total_item_sales DESC, d_date
LIMIT 100

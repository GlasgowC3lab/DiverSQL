WITH sales_with_details AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_category_id,
        i.i_current_price,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_warehouse_sk,
        w.w_warehouse_name,
        w.w_state,
        ws.ws_promo_sk,
        p.p_promo_name,
        p.p_end_date_sk AS promo_end_sk,
        ws.ws_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ws.ws_web_page_sk,
        wp.wp_type,
        ws.ws_ship_mode_sk,
        CASE WHEN ws.ws_net_profit > 1000 THEN 'High' ELSE 'Normal' END AS profit_level
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
)
SELECT
    sd.ws_order_number,
    sd.i_item_id,
    sd.i_category,
    sd.w_warehouse_name,
    sd.w_state,
    sd.c_first_name,
    sd.c_last_name,
    sd.profit_level,
    sd.ws_ext_sales_price,
    COALESCE(rd.wr_return_quantity, 0) AS return_quantity,
    COALESCE(rd.wr_return_amt, 0) AS return_amount,
    COALESCE(inv.inv_quantity_on_hand, 0) AS inventory_on_hand,
    RANK() OVER (PARTITION BY sd.w_state ORDER BY sd.ws_ext_sales_price DESC) AS sales_rank_state,
    dim.dim_value
FROM sales_with_details sd
LEFT JOIN web_returns rd
    ON rd.wr_order_number = sd.ws_order_number
LEFT JOIN inventory inv
    ON inv.inv_item_sk = sd.ws_item_sk
    AND inv.inv_warehouse_sk = sd.ws_warehouse_sk
CROSS JOIN (
    SELECT 1 AS dim_value UNION ALL SELECT 2 UNION ALL SELECT 3
) dim
WHERE sd.i_category_id IN (1, 2)
  AND sd.promo_end_sk > 2450300
  AND sd.w_state = 'CA'
ORDER BY sales_rank_state, sd.ws_order_number
LIMIT 100

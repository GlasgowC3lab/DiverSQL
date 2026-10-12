-- Goal: Analyze sales and returns performance by promotion and year, keeping promotions with no sales (right join), and showing subtotals and grand total.
WITH base_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_addr_sk
    FROM catalog_sales cs
    WHERE cs.cs_item_sk IN (
            SELECT i.i_item_sk
            FROM item i
            WHERE i.i_category = 'Electronics'
        )
      AND cs.cs_quantity > (
            SELECT AVG(cs2.cs_quantity)
            FROM catalog_sales cs2
        )
)
SELECT
    p.p_promo_name,
    d_sales.d_year,
    SUM(base_sales.cs_net_paid) AS total_sales_amount,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_loss,
    SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales_amount,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_return_loss
FROM base_sales
RIGHT JOIN promotion p
    ON base_sales.cs_promo_sk = p.p_promo_sk
LEFT JOIN date_dim d_sales
    ON base_sales.cs_sold_date_sk = d_sales.d_date_sk
LEFT JOIN time_dim t_sales
    ON base_sales.cs_sold_time_sk = t_sales.t_time_sk
LEFT JOIN item i
    ON base_sales.cs_item_sk = i.i_item_sk
LEFT JOIN call_center cc
    ON base_sales.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp
    ON base_sales.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm
    ON base_sales.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN customer c_bill
    ON base_sales.cs_bill_customer_sk = c_bill.c_customer_sk
LEFT JOIN customer_address ca_bill
    ON base_sales.cs_bill_addr_sk = ca_bill.ca_address_sk
-- Store returns and related dimensions
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = base_sales.cs_item_sk
LEFT JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
LEFT JOIN time_dim t_sr
    ON sr.sr_return_time_sk = t_sr.t_time_sk
LEFT JOIN customer c_ret
    ON sr.sr_customer_sk = c_ret.c_customer_sk
LEFT JOIN customer_address ca_ret
    ON sr.sr_addr_sk = ca_ret.ca_address_sk
-- Web sales and related dimensions
LEFT JOIN web_sales ws
    ON ws.ws_item_sk = base_sales.cs_item_sk
LEFT JOIN date_dim d_ws
    ON ws.ws_sold_date_sk = d_ws.d_date_sk
LEFT JOIN time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN customer c_ws
    ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
LEFT JOIN customer_address ca_ws
    ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
-- Web returns and related dimensions
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
LEFT JOIN customer c_wr_ref
    ON wr.wr_refunded_customer_sk = c_wr_ref.c_customer_sk
LEFT JOIN customer_address ca_wr_ref
    ON wr.wr_refunded_addr_sk = ca_wr_ref.ca_address_sk
-- Catalog returns (joined via order number)
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = base_sales.cs_order_number
LEFT JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
LEFT JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
GROUP BY ROLLUP (p.p_promo_name, d_sales.d_year)
ORDER BY p.p_promo_name, d_sales.d_year
LIMIT 100

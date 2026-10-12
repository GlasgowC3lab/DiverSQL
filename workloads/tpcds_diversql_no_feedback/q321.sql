WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        d_sold.d_year,
        sm.sm_carrier,
        w.w_state,
        cs.cs_net_paid,
        wr.wr_net_loss,
        p.p_cost,
        p.p_discount_active,
        i.inv_quantity_on_hand,
        ib.ib_lower_bound,
        cp.cp_type,
        cs.cs_ext_discount_amt,
        cs.cs_bill_customer_sk
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk AND i.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN web_sales ws ON ws.ws_order_number = cs.cs_order_number
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 1 = 1
)
SELECT
    b.d_year,
    b.sm_carrier,
    b.w_state,
    SUM(b.cs_net_paid) AS total_sales,
    SUM(b.wr_net_loss) AS total_returns_loss,
    COUNT(DISTINCT b.cs_order_number) AS order_cnt,
    AVG(b.p_cost) AS avg_promo_cost,
    MIN(b.inv_quantity_on_hand) AS min_inventory,
    MAX(b.inv_quantity_on_hand) AS max_inventory,
    AVG(ld.order_discount_total) AS avg_order_discount
FROM base b
CROSS JOIN LATERAL (
    SELECT SUM(cs2.cs_ext_discount_amt) AS order_discount_total
    FROM catalog_sales cs2
    WHERE cs2.cs_order_number = b.cs_order_number
) ld
WHERE b.d_year = 2001
  AND b.sm_carrier = 'FEDEX'
  AND b.ib_lower_bound >= 120000
  AND b.w_state = 'CA'
  AND b.cp_type = 'Electronic'
  AND b.p_discount_active = 'Y'
GROUP BY b.d_year, b.sm_carrier, b.w_state

UNION

SELECT
    b.d_year,
    b.sm_carrier,
    b.w_state,
    SUM(b.cs_net_paid) AS total_sales,
    SUM(b.wr_net_loss) AS total_returns_loss,
    COUNT(DISTINCT b.cs_order_number) AS order_cnt,
    AVG(b.p_cost) AS avg_promo_cost,
    MIN(b.inv_quantity_on_hand) AS min_inventory,
    MAX(b.inv_quantity_on_hand) AS max_inventory,
    AVG(ld.order_discount_total) AS avg_order_discount
FROM base b
CROSS JOIN LATERAL (
    SELECT SUM(cs2.cs_ext_discount_amt) AS order_discount_total
    FROM catalog_sales cs2
    WHERE cs2.cs_order_number = b.cs_order_number
) ld
WHERE b.d_year = 2002
  AND b.sm_carrier = 'AIRBORNE'
  AND b.ib_lower_bound >= 110000
  AND b.w_state = 'TX'
  AND b.cp_type = 'Physical'
  AND b.p_discount_active = 'N'
GROUP BY b.d_year, b.sm_carrier, b.w_state

ORDER BY total_sales DESC
LIMIT 100

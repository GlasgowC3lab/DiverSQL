WITH cat_cust AS (
    SELECT DISTINCT c.c_customer_sk
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND w.w_state IN ('MO','MI')
      AND cs.cs_net_profit > 500
),
store_cust AS (
    SELECT DISTINCT c.c_customer_sk
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ss.ss_net_profit > 500
),
common_customers AS (
    SELECT c_customer_sk FROM cat_cust
    INTERSECT
    SELECT c_customer_sk FROM store_cust
)
SELECT *
FROM (
    SELECT
        w.w_warehouse_sk,
        w.w_state,
        w.w_warehouse_name,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit)) DESC) AS rk
    FROM common_customers cc
    JOIN customer c ON cc.c_customer_sk = c.c_customer_sk
    -- catalog side
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center ccg ON cs.cs_call_center_sk = ccg.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r_cat ON cr.cr_reason_sk = r_cat.r_reason_sk
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk AND inv.inv_date_sk = d_cs.d_date_sk
    -- store side
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    WHERE d_cs.d_year = 2001
      AND w.w_state IN ('MO','MI')
      AND p.p_discount_active = 'Y'
      AND cs.cs_net_profit > 0
      AND ss.ss_net_profit > 0
    GROUP BY w.w_warehouse_sk, w.w_state, w.w_warehouse_name
) t
WHERE rk <= 5
ORDER BY total_profit DESC
LIMIT 100

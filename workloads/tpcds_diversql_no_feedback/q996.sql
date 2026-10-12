WITH joined_data AS (
    SELECT
        cc.cc_name,
        cp.cp_type,
        s.s_store_name,
        i.i_category,
        cs.cs_net_paid,
        ss.ss_net_paid,
        COALESCE(cr.cr_return_amount, 0) AS cr_return_amount,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    -- bridge to store information via store_sales and the shared item key
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t_ss
        ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    -- bill‑side customer and demographics
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    -- ship‑side customer and demographics (different aliases)
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    -- return‑side customers (optional, left‑joined)
    LEFT JOIN customer c_refunded
        ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    LEFT JOIN customer c_returning
        ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    LEFT JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    LEFT JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
)
SELECT
    cc_name,
    cp_type,
    s_store_name,
    i_category,
    SUM(cs_net_paid)               AS total_catalog_sales,
    SUM(ss_net_paid)               AS total_store_sales,
    SUM(cr_return_amount)          AS total_returns,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    RANK() OVER (ORDER BY SUM(cs_net_paid) DESC) AS sales_rank
FROM joined_data
GROUP BY ROLLUP (cc_name, cp_type, s_store_name, i_category)
LIMIT 100

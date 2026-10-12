WITH sales_data AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        sm.sm_type,
        w.w_state,
        hd.hd_income_band_sk,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inventory inv
        ON w.w_warehouse_sk = inv.inv_warehouse_sk
       AND inv.inv_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    WHERE cp.cp_start_date_sk BETWEEN 2450800 AND 2450900
      AND cp.cp_end_date_sk BETWEEN 2450900 AND 2451000
    GROUP BY cp.cp_catalog_page_id, cp.cp_department, sm.sm_type, w.w_state, hd.hd_income_band_sk
),

returns_data AS (
    SELECT
        cp.cp_catalog_page_id,
        sm.sm_type,
        w.w_state,
        hd.hd_income_band_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cp.cp_start_date_sk BETWEEN 2450800 AND 2450900
      AND cp.cp_end_date_sk BETWEEN 2450900 AND 2451000
    GROUP BY cp.cp_catalog_page_id, sm.sm_type, w.w_state, hd.hd_income_band_sk
)

SELECT
    s.cp_catalog_page_id,
    s.cp_department,
    s.sm_type,
    s.w_state,
    s.hd_income_band_sk,
    s.total_sales,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales,
    s.total_quantity,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    s.avg_discount,
    s.avg_inventory_on_hand,
    s.distinct_orders,
    RANK() OVER (ORDER BY (s.total_sales - COALESCE(r.total_return_amount, 0)) DESC) AS sales_rank
FROM sales_data s
LEFT JOIN returns_data r
    ON s.cp_catalog_page_id = r.cp_catalog_page_id
   AND s.sm_type = r.sm_type
   AND s.w_state = r.w_state
   AND s.hd_income_band_sk = r.hd_income_band_sk
ORDER BY net_sales DESC
LIMIT 50

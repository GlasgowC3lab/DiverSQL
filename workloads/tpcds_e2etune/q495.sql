WITH sales_agg AS (
    SELECT
        cc.cc_name AS call_center_name,
        cc.cc_state,
        sm.sm_type AS ship_type,
        cp.cp_department AS department,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cc.cc_state IN ('TN', 'GA')
      AND cc.cc_gmt_offset = -5.00
      AND cp.cp_type = 'PROMO'
      AND cs.cs_sold_date_sk BETWEEN 2450806 AND 2451063
    GROUP BY cc.cc_name, cc.cc_state, sm.sm_type, cp.cp_department
    HAVING SUM(cs.cs_net_paid) > 50000
)
SELECT
    call_center_name,
    cc_state,
    ship_type,
    department,
    total_sales,
    total_profit,
    avg_discount,
    num_orders,
    total_quantity,
    total_profit / total_sales AS profit_margin,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY profit_margin DESC
LIMIT 20

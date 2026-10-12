WITH sales_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state,
        cc.cc_class,
        sm.sm_type,
        cp.cp_department,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cc.cc_state = 'TN'
      AND cc.cc_class = 'large'
      AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cc.cc_call_center_sk, cc.cc_name, cc.cc_state, cc.cc_class, sm.sm_type, cp.cp_department
),
returns_agg AS (
    SELECT
        cr.cr_call_center_sk AS cc_call_center_sk,
        sm.sm_type,
        cp.cp_department,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS num_returns
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cr.cr_call_center_sk, sm.sm_type, cp.cp_department
)
SELECT
    s.cc_name,
    s.cc_state,
    s.sm_type,
    s.cp_department,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales - COALESCE(r.total_return_loss, 0) AS net_sales_after_returns,
    s.num_orders,
    COALESCE(r.num_returns, 0) AS num_returns,
    CASE WHEN s.total_sales > 0 THEN (s.total_sales - COALESCE(r.total_return_loss, 0)) / s.total_sales ELSE NULL END AS sales_retention_ratio,
    RANK() OVER (ORDER BY (s.total_sales - COALESCE(r.total_return_loss, 0)) DESC) AS sales_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cc_call_center_sk = r.cc_call_center_sk
   AND s.sm_type = r.sm_type
   AND s.cp_department = r.cp_department
ORDER BY sales_rank
LIMIT 20

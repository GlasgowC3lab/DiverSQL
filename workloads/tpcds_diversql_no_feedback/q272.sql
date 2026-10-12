WITH base AS (
    SELECT
        d.d_year,
        s.s_state,
        cp.cp_department,
        cc.cc_name,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_order_number,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND cp.cp_department = 'DEPARTMENT'
      AND cc.cc_market_manager = 'John Doe'
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          WHERE ws.ws_sold_date_sk = cs.cs_sold_date_sk
            AND ws.ws_net_paid > 0
      )
)
SELECT
    d_year,
    s_state,
    cp_department,
    cc_name,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_quantity) AS avg_quantity,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    MIN(cs_ext_discount_amt) AS min_discount,
    MAX(cs_ext_discount_amt) AS max_discount
FROM base
GROUP BY CUBE (d_year, s_state, cp_department, cc_name)
ORDER BY d_year ASC, s_state ASC, cp_department ASC, cc_name ASC
LIMIT 100

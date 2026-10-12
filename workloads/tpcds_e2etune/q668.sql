WITH base AS (
    SELECT
        cp.cp_department AS department,
        cp.cp_catalog_number AS catalog_number,
        cp.cp_catalog_page_number AS catalog_page_number,
        sm.sm_type AS ship_mode_type,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        AVG(ib.ib_lower_bound) AS avg_income_lower_bound
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_start_date_sk BETWEEN 2450800 AND 2451000
      AND sm.sm_type = 'AIR'
    GROUP BY
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        sm.sm_type
)
SELECT
    department,
    catalog_number,
    catalog_page_number,
    ship_mode_type,
    total_net_profit,
    total_net_paid,
    avg_discount,
    distinct_customers,
    avg_income_lower_bound,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM base
WHERE total_net_profit > 10000
ORDER BY profit_rank
LIMIT 10

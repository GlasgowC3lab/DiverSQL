/*
Goal: Identify the top‑selling catalog orders per Call Center state for California customers born between 1950 and 1980, who belong to households with at least one vehicle. The query joins all six TPC‑DS tables, applies multiple filters, ranks sales within each state, tags orders by quantity, and compares the income‑band upper bound against the overall maximum income band.
*/
WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_call_center_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        c.c_customer_id,
        c.c_birth_year,
        cc.cc_name,
        cc.cc_state,
        hd.hd_vehicle_count,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM catalog_sales cs
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
      AND cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state = 'CA'
      AND hd.hd_vehicle_count >= 1
      AND c.c_birth_year BETWEEN 1950 AND 1980
      AND ib.ib_upper_bound < (SELECT max(ib2.ib_upper_bound) FROM income_band ib2)
)
SELECT
    base.cs_order_number,
    base.c_customer_id,
    base.c_birth_year,
    base.cc_name,
    base.cc_state,
    base.hd_vehicle_count,
    base.hd_buy_potential,
    base.ib_lower_bound,
    base.ib_upper_bound,
    base.cs_quantity,
    base.cs_net_paid,
    RANK() OVER (PARTITION BY base.cc_state ORDER BY base.cs_net_paid DESC) AS state_sales_rank,
    CASE WHEN base.cs_quantity > 10 THEN 'Large' ELSE 'Small' END AS qty_category
FROM base
ORDER BY state_sales_rank ASC, base.cs_net_paid DESC
LIMIT 100

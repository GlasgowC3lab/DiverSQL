WITH warehouse_metrics AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        ca.ca_city AS billing_city,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount_amt,
        COUNT(DISTINCT cs.cs_bill_hdemo_sk) AS distinct_bill_households,
        AVG(hd_bill.hd_vehicle_count) AS avg_vehicle_per_household,
        CASE 
            WHEN SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0) > 0.20 THEN 'HIGH_PROFIT'
            ELSE 'NORMAL_PROFIT'
        END AS profit_category
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        ca.ca_city
)
SELECT
    wm.*,
    RANK() OVER (ORDER BY wm.total_net_paid DESC) AS revenue_rank
FROM warehouse_metrics wm
ORDER BY revenue_rank

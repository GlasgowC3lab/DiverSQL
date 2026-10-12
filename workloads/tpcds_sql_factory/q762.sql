WITH promo_metrics AS (
    SELECT
        cs.cs_promo_sk,
        ca.ca_state,
        w.w_state AS warehouse_state,
        hd_bill.hd_buy_potential,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_ext_tax) AS total_tax,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(cs.cs_quantity) AS avg_quantity
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    GROUP BY
        cs.cs_promo_sk,
        ca.ca_state,
        w.w_state,
        hd_bill.hd_buy_potential
)
SELECT
    pm.cs_promo_sk,
    pm.ca_state,
    pm.warehouse_state,
    pm.hd_buy_potential,
    pm.total_discount,
    pm.total_tax,
    pm.total_net_paid_inc_tax,
    pm.total_net_paid,
    pm.avg_quantity,
    CASE
        WHEN pm.total_discount / NULLIF(pm.total_net_paid, 0) > 0.15 THEN 'AGGRESSIVE'
        ELSE 'NORMAL'
    END AS promo_aggressiveness,
    DENSE_RANK() OVER (PARTITION BY pm.ca_state ORDER BY pm.total_discount DESC) AS discount_rank_state,
    RANK() OVER (ORDER BY pm.total_discount DESC) AS global_discount_rank,
    SUM(pm.total_discount) OVER (PARTITION BY pm.ca_state) AS state_total_discount
FROM promo_metrics pm
WHERE pm.total_discount / NULLIF(pm.total_net_paid, 0) > 0.15
ORDER BY pm.ca_state, discount_rank_state

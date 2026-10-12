WITH cust_income AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        c.c_current_addr_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer c
    JOIN income_band ib ON c.c_current_cdemo_sk = ib.ib_income_band_sk
    WHERE c.c_birth_year BETWEEN 1950 AND 1970
),
inv_ship AS (
    SELECT 
        i.inv_warehouse_sk,
        i.inv_item_sk,
        SUM(i.inv_quantity_on_hand) AS total_qty
    FROM inventory i
    WHERE i.inv_quantity_on_hand > 0
    GROUP BY i.inv_warehouse_sk, i.inv_item_sk
),
reason_counts AS (
    SELECT 
        r.r_reason_sk,
        COUNT(*) AS reason_cnt,
        r.r_reason_desc
    FROM reason r
    GROUP BY r.r_reason_sk, r.r_reason_desc
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.c_birth_year,
    ci.ib_lower_bound,
    ci.ib_upper_bound,
    sm.sm_carrier,
    sm.sm_type,
    SUM(isagg.total_qty) AS total_inventory_qty,
    COUNT(DISTINCT rc.r_reason_desc) AS distinct_reason_desc_cnt,
    RANK() OVER (PARTITION BY sm.sm_carrier ORDER BY SUM(isagg.total_qty) DESC) AS carrier_qty_rank
FROM cust_income ci
JOIN inv_ship isagg ON ci.c_current_addr_sk = isagg.inv_warehouse_sk
JOIN ship_mode sm ON isagg.inv_warehouse_sk = sm.sm_ship_mode_sk
LEFT JOIN reason_counts rc ON isagg.inv_item_sk = rc.r_reason_sk
WHERE ci.ib_lower_bound >= 20000
GROUP BY 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.c_birth_year,
    ci.ib_lower_bound,
    ci.ib_upper_bound,
    sm.sm_carrier,
    sm.sm_type
HAVING SUM(isagg.total_qty) > 1000
ORDER BY total_inventory_qty DESC
LIMIT 100

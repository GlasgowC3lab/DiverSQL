WITH
    bill_ca AS (
        SELECT ca_address_sk, ca_state, ca_city, ca_gmt_offset, ca_location_type
        FROM customer_address
        WHERE ca_state = 'CA' AND ca_gmt_offset = -5.00
    ),
    ship_ca AS (
        SELECT ca_address_sk, ca_state AS ship_state, ca_city AS ship_city
        FROM customer_address
        WHERE ca_state = 'TX'
    )
SELECT
    c.c_first_name,
    c.c_last_name,
    bill_ca.ca_city,
    ship_ca.ship_city,
    sm.sm_type,
    w.w_state,
    p.p_promo_name,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    MIN(cs.cs_net_paid) AS min_net_paid,
    MAX(cs.cs_net_paid) AS max_net_paid
FROM catalog_sales cs
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN bill_ca
    ON cs.cs_bill_addr_sk = bill_ca.ca_address_sk
JOIN ship_ca
    ON cs.cs_ship_addr_sk = ship_ca.ca_address_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE
    c.c_salutation = 'Mr.'
    AND c.c_preferred_cust_flag = 'Y'
    AND p.p_channel_radio = 'N'
    AND p.p_discount_active = 'Y'
    AND sm.sm_carrier = 'UPS'
    AND w.w_state = 'TX'
GROUP BY CUBE (
    c.c_first_name,
    c.c_last_name,
    bill_ca.ca_city,
    ship_ca.ship_city,
    sm.sm_type,
    w.w_state,
    p.p_promo_name
)
ORDER BY total_net_paid DESC
LIMIT 100

WITH intersect_items AS (
    SELECT cs.cs_item_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
    INTERSECT
    SELECT wr.wr_item_sk
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 0
)
SELECT
    c.c_customer_id,
    i.i_item_id,
    p.p_promo_name,
    sm.sm_ship_mode_id,
    td.t_hour,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_quantity) AS avg_quantity,
    COUNT(*) AS sales_count,
    MIN(cs.cs_ext_discount_amt) AS min_discount,
    MAX(cs.cs_ext_tax) AS max_tax,
    (
        SELECT SUM(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
    ) AS total_return_amount
FROM catalog_sales cs
JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_returns wr
    ON cs.cs_item_sk = wr.wr_item_sk
JOIN intersect_items ii
    ON cs.cs_item_sk = ii.cs_item_sk
WHERE
    c.c_birth_country = 'SWITZERLAND'
    AND ca.ca_country = 'CHILE'
    AND sm.sm_carrier = 'FEDEX'
    AND i.i_formulation = 'snow1543775706017405'
    AND i.i_manager_id = 23
    AND p.p_discount_active = 'Y'
GROUP BY
    c.c_customer_id,
    i.i_item_id,
    p.p_promo_name,
    sm.sm_ship_mode_id,
    td.t_hour,
    c.c_customer_sk
ORDER BY total_net_paid DESC
LIMIT 100

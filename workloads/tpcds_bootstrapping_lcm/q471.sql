SELECT
    d.d_year,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_state AS ship_state,
    s.s_division_name,
    wp.wp_type,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_ext_discount_amt) AS total_discount,
    COUNT(*) AS sales_cnt,
    SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid), 0) AS profit_margin,
    SUM(CASE WHEN cs.cs_quantity > 5 THEN cs.cs_net_paid ELSE 0 END) AS net_paid_large_qty,
    SUM(CASE WHEN cs.cs_quantity <= 5 THEN cs.cs_net_paid ELSE 0 END) AS net_paid_small_qty,
    (SUM(cs.cs_net_paid) - SUM(cs.cs_ext_discount_amt)) AS net_after_discount
FROM catalog_sales cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
WHERE cs.cs_net_paid > 0
GROUP BY
    d.d_year,
    ca_bill.ca_state,
    ca_ship.ca_state,
    s.s_division_name,
    wp.wp_type
HAVING COUNT(*) > 10
ORDER BY total_net_paid DESC
LIMIT 100

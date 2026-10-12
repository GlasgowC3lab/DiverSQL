WITH
    filtered AS (
        SELECT
            cs.cs_sold_date_sk,
            cs.cs_order_number,
            cs.cs_quantity,
            cs.cs_net_paid,
            cs.cs_item_sk,
            c.c_customer_sk,
            cd.cd_gender,
            ca.ca_location_type,
            sm.sm_type,
            p.p_channel_email,
            d.d_year
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        WHERE d.d_year = 2001
          AND ca.ca_location_type = 'condo'
          AND cd.cd_gender = 'F'
          AND p.p_channel_email = 'Y'
    ),
    intersect_keys AS (
        SELECT cs_order_number AS order_num FROM catalog_sales WHERE cs_sold_date_sk = 2450
        INTERSECT
        SELECT cr_order_number FROM catalog_returns WHERE cr_returned_date_sk = 2450
    )
SELECT
    d.d_year,
    sm.sm_type,
    SUM(f.cs_net_paid) AS total_net_paid,
    AVG(f.cs_quantity) AS avg_quantity,
    COUNT(*) AS order_count,
    CASE WHEN SUM(f.cs_net_paid) > 1000000 THEN 'HIGH' ELSE 'LOW' END AS revenue_category
FROM filtered f
JOIN catalog_returns cr ON cr.cr_order_number = f.cs_order_number
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
WHERE f.cs_order_number IN (SELECT order_num FROM intersect_keys)
  AND f.cs_quantity > (
        SELECT AVG(cs2.cs_quantity)
        FROM catalog_sales cs2
        WHERE cs2.cs_sold_date_sk = 2450
    )
GROUP BY d.d_year, sm.sm_type
HAVING SUM(f.cs_net_paid) > 500000
ORDER BY total_net_paid DESC

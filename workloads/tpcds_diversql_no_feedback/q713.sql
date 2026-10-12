WITH computed_set AS (
    SELECT 1 AS grp UNION ALL SELECT 2 AS grp
)
SELECT
    p.p_promo_name,
    sm.sm_type,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    AVG(cs.cs_ext_sales_price) AS avg_sales_price,
    MAX(cs.cs_ext_sales_price) AS max_sales_price,
    cs_grp.grp
FROM
    catalog_sales cs
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN catalog_page cp_ret ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
    JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
    JOIN customer c_ret ON cr.cr_refunded_customer_sk = c_ret.c_customer_sk
    JOIN customer c_retng ON cr.cr_returning_customer_sk = c_retng.c_customer_sk
    CROSS JOIN computed_set cs_grp
WHERE
    cs.cs_ext_sales_price > (
        SELECT MAX(cs3.cs_ext_sales_price)
        FROM catalog_sales cs3
        WHERE cs3.cs_quantity = 1
    )
    AND cs.cs_catalog_page_sk IN (
        SELECT cp2.cp_catalog_page_sk
        FROM catalog_page cp2
        WHERE cp2.cp_department = 'Electronics'
    )
GROUP BY
    p.p_promo_name,
    sm.sm_type,
    cs_grp.grp
HAVING
    SUM(cs.cs_net_profit) > (
        SELECT AVG(cs4.cs_net_profit)
        FROM catalog_sales cs4
        WHERE cs4.cs_quantity = 1
    )
ORDER BY
    total_net_profit DESC
LIMIT 100

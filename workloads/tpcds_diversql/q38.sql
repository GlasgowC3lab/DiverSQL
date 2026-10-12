WITH orders_without_returns AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
)
SELECT
    r.r_reason_desc AS reason_description,
    sm.sm_type AS ship_mode_type,
    d_sold.d_year AS sold_year,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount
FROM catalog_sales AS cs
RIGHT JOIN call_center AS cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
INNER JOIN catalog_page AS cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN ship_mode AS sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN promotion AS p
    ON cs.cs_promo_sk = p.p_promo_sk
INNER JOIN customer AS c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
INNER JOIN customer_demographics AS cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
INNER JOIN customer AS c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
INNER JOIN customer_demographics AS cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
INNER JOIN date_dim AS d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
INNER JOIN date_dim AS d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
LEFT JOIN catalog_returns AS cr
    ON cs.cs_order_number = cr.cr_order_number
INNER JOIN reason AS r
    ON cr.cr_reason_sk = r.r_reason_sk
WHERE cs.cs_order_number IN (SELECT cs_order_number FROM orders_without_returns)
  AND cs.cs_net_profit > (SELECT MAX(p_cost) FROM promotion)
GROUP BY r.r_reason_desc, sm.sm_type, d_sold.d_year
HAVING SUM(cs.cs_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100

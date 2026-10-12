WITH dept_profit AS (
    SELECT
        cp.cp_department AS department,
        sm.sm_code AS ship_mode_code,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE sm.sm_contract IN ('uukTktPYycct8', 'A5BYO1qH8HGTTN')
      AND sm.sm_code = 'AIR'
      AND cs.cs_coupon_amt > 0
      AND c.c_birth_day = 7
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY cp.cp_department, sm.sm_code
)
SELECT
    department,
    ship_mode_code,
    total_net_profit,
    total_quantity,
    total_sales,
    order_count,
    CASE WHEN total_net_profit > 100000 THEN 'High' ELSE 'Medium' END AS profit_category,
    RANK() OVER (PARTITION BY ship_mode_code ORDER BY total_net_profit DESC) AS profit_rank
FROM dept_profit
ORDER BY profit_rank ASC, total_net_profit DESC
LIMIT 100

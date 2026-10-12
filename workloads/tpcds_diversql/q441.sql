WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
),
sales_customers AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        CASE WHEN cp.cp_department = 'Electronics' THEN 'Electronics' ELSE 'Other' END AS dept_category,
        cs.cs_ext_list_price,
        cs.cs_net_paid_inc_ship
    FROM sampled_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier = 'FEDEX'
      AND cs.cs_ext_list_price > 1000
),
return_customers AS (
    SELECT DISTINCT cr.cr_returning_customer_sk AS customer_sk
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier = 'FEDEX'
),
purchaser_set AS (
    SELECT sc.customer_sk, sc.dept_category, sc.cs_ext_list_price, sc.cs_net_paid_inc_ship
    FROM sales_customers sc
    EXCEPT
    SELECT rc.customer_sk, NULL, NULL, NULL
    FROM return_customers rc
)
SELECT
    p.customer_sk,
    p.dept_category,
    (p.cs_ext_list_price + p.cs_net_paid_inc_ship) AS total_sales,
    ROW_NUMBER() OVER (ORDER BY (p.cs_ext_list_price + p.cs_net_paid_inc_ship) DESC) AS row_num,
    l.purchase_events
FROM purchaser_set p
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS purchase_events
    FROM catalog_sales cs3
    WHERE cs3.cs_bill_customer_sk = p.customer_sk
) l
WHERE (p.cs_ext_list_price + p.cs_net_paid_inc_ship) > 0
ORDER BY total_sales DESC, p.customer_sk
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

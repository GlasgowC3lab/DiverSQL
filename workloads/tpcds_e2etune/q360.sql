WITH daily_inventory AS (
    SELECT inv.inv_date_sk AS date_sk,
           AVG(inv.inv_quantity_on_hand) AS avg_inv_qty
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY inv.inv_date_sk
)
SELECT cc.cc_name,
       cc.cc_state,
       cc.cc_employees,
       SUM(cs.cs_net_profit) AS total_net_profit,
       SUM(cs.cs_net_paid) AS total_net_paid,
       COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
       COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
       AVG(cs.cs_ext_discount_amt) AS avg_discount,
       AVG(di.avg_inv_qty) AS avg_daily_inventory,
       CASE WHEN cc.cc_employees > 0 THEN SUM(cs.cs_net_profit) / cc.cc_employees ELSE NULL END AS profit_per_employee
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN daily_inventory di ON cs.cs_sold_date_sk = di.date_sk
WHERE d.d_year = 2020
  AND cc.cc_state IN ('TN', 'GA')
  AND ca.ca_country = 'United States'
GROUP BY cc.cc_name, cc.cc_state, cc.cc_employees
HAVING SUM(cs.cs_net_profit) > 10000
ORDER BY profit_per_employee DESC
LIMIT 10

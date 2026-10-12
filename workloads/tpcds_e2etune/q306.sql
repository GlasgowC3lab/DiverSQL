WITH sales_by_cust_dept AS (
    SELECT
        c.c_customer_sk,
        cp.cp_department,
        SUM(cs.cs_net_profit) AS sales_profit,
        SUM(cs.cs_quantity) AS sales_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS sales_orders
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND c.c_birth_country = 'United States'
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY c.c_customer_sk, cp.cp_department
),
returns_by_cust AS (
    SELECT
        c.c_customer_sk,
        SUM(sr.sr_net_loss) AS return_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_tickets
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND c.c_birth_country = 'United States'
      AND sr.sr_returned_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY c.c_customer_sk
)
SELECT
    s.cp_department,
    SUM(s.sales_profit) AS total_sales_profit,
    SUM(r.return_loss) AS total_return_loss,
    SUM(s.sales_profit) - SUM(r.return_loss) AS net_revenue,
    SUM(s.sales_quantity) AS total_sales_quantity,
    SUM(s.sales_orders) AS total_sales_orders,
    SUM(r.return_tickets) AS total_return_tickets,
    ROUND(100.0 * SUM(r.return_loss) / NULLIF(SUM(s.sales_profit), 0), 2) AS loss_pct_of_profit,
    DENSE_RANK() OVER (ORDER BY SUM(s.sales_profit) - SUM(r.return_loss) DESC) AS dept_rank
FROM sales_by_cust_dept s
JOIN returns_by_cust r ON s.c_customer_sk = r.c_customer_sk
GROUP BY s.cp_department
HAVING SUM(s.sales_profit) > 1000
ORDER BY net_revenue DESC
LIMIT 10

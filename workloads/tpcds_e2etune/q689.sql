WITH agg AS (
  SELECT
    cp.cp_department AS department,
    cs.cs_sold_date_sk AS sold_date_sk,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cs.cs_net_paid) AS total_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE cp.cp_department = 'DEPARTMENT'
    AND ca.ca_country = 'United States'
    AND c.c_preferred_cust_flag = 'Y'
    AND cs.cs_sold_date_sk BETWEEN 2450905 AND 2451087
  GROUP BY cp.cp_department, cs.cs_sold_date_sk
),
ranked AS (
  SELECT
    department,
    sold_date_sk,
    total_profit,
    total_paid,
    avg_discount,
    distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY total_profit DESC) AS profit_rank
  FROM agg
)
SELECT
  department,
  sold_date_sk,
  total_profit,
  total_paid,
  avg_discount,
  distinct_customers,
  profit_rank
FROM ranked
WHERE profit_rank <= 5
ORDER BY department, profit_rank

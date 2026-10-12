WITH dept_sales AS (
  SELECT
    cp.cp_department AS department,
    cs.cs_sold_date_sk AS sold_date_sk,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_bill_customers
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  WHERE cp.cp_catalog_number IN (1, 2)
    AND cp.cp_end_date_sk > 2450800
    AND cs.cs_quantity > 0
    AND cs.cs_net_profit > 0
  GROUP BY cp.cp_department, cs.cs_sold_date_sk
)
SELECT
  department,
  sold_date_sk,
  total_net_profit,
  total_sales,
  avg_discount,
  distinct_bill_customers,
  RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM dept_sales
ORDER BY profit_rank, department
LIMIT 100

WITH sales_detail AS (
  SELECT
    w.w_state,
    w.w_warehouse_name,
    cs.cs_net_profit,
    cp.cp_description,
    cp.cp_catalog_page_id,
    c.c_customer_sk,
    concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    c.c_email_address,
    regexp_extract(c.c_email_address, '([^@]+)@(.+)$', 2) AS email_domain,
    d.d_year,
    d.d_month_seq
  FROM catalog_sales cs
  INNER JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  INNER JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  INNER JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  INNER JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE regexp_like(cp.cp_description, '(?i)discount')
    AND cp.cp_catalog_page_id LIKE 'A%'
    AND c.c_email_address LIKE '%@gmail.com'
),
agg_sales AS (
  SELECT
    w_state,
    w_warehouse_name,
    SUM(cs_net_profit) AS total_net_profit,
    COUNT(*) AS sales_count
  FROM sales_detail
  GROUP BY w_state, w_warehouse_name
)
SELECT
  w_state,
  w_warehouse_name,
  total_net_profit,
  sales_count,
  ROW_NUMBER() OVER (PARTITION BY w_state ORDER BY total_net_profit DESC) AS warehouse_rank
FROM agg_sales
ORDER BY total_net_profit DESC
LIMIT 100

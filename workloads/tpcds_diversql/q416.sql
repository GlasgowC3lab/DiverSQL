WITH page_dates AS (
   SELECT
       cp.cp_catalog_page_sk,
       cp.cp_department,
       d_start.d_year   AS start_year,
       d_end.d_year     AS end_year
   FROM catalog_page cp
   FULL OUTER JOIN date_dim d_start
       ON cp.cp_start_date_sk = d_start.d_date_sk
   LEFT JOIN date_dim d_end
       ON cp.cp_end_date_sk = d_end.d_date_sk
),
sales_enriched AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_sold_time_sk,
       cs.cs_warehouse_sk,
       cs.cs_item_sk,
       cs.cs_bill_addr_sk,
       cs.cs_catalog_page_sk,
       cs.cs_quantity,
       cs.cs_net_paid,
       cs.cs_net_profit,
       d.d_year,
       t.t_time,
       w.w_warehouse_name,
       i.i_category,
       i.i_category_id,
       ca.ca_state,
       pd.cp_department
   FROM catalog_sales cs
   JOIN date_dim d
       ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t
       ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN warehouse w
       ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN item i
       ON cs.cs_item_sk = i.i_item_sk
   JOIN customer_address ca
       ON cs.cs_bill_addr_sk = ca.ca_address_sk
   LEFT JOIN page_dates pd
       ON cs.cs_catalog_page_sk = pd.cp_catalog_page_sk
   WHERE d.d_year BETWEEN 1998 AND 2001
     AND i.i_category_id IN (1, 5, 9)
     AND ca.ca_state IN ('CA', 'TX', 'NY')
),
agg_sales AS (
   SELECT
       d_year,
       i_category,
       w_warehouse_name,
       cp_department,
       SUM(cs_quantity)      AS sum_qty,
       SUM(cs_net_paid)      AS sum_net_paid,
       SUM(cs_net_profit)    AS sum_net_profit
   FROM sales_enriched
   GROUP BY d_year, i_category, w_warehouse_name, cp_department
),
agg_positive AS (
   SELECT d_year, i_category, sum_net_paid
   FROM agg_sales
   WHERE sum_net_paid > 5000
),
agg_negative AS (
   SELECT d_year, i_category, sum_net_paid
   FROM agg_sales
   WHERE sum_net_paid < 2000
),
final_set AS (
   SELECT d_year, i_category, sum_net_paid
   FROM agg_positive
   EXCEPT
   SELECT d_year, i_category, sum_net_paid
   FROM agg_negative
)
SELECT
   f.d_year,
   f.i_category,
   f.sum_net_paid,
   LAG(f.sum_net_paid) OVER (PARTITION BY f.i_category ORDER BY f.d_year) AS lag_net_paid,
   ROW_NUMBER() OVER (ORDER BY f.sum_net_paid DESC) AS rn
FROM final_set f
ORDER BY f.sum_net_paid DESC
LIMIT 100

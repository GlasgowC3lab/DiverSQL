WITH sampled_cs AS (
   SELECT *
   FROM catalog_sales TABLESAMPLE BERNOULLI (10)
),
base_join AS (
   SELECT
      cp.cp_department,
      d.d_year,
      t.t_hour,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ss.ss_net_paid,
      sr.sr_return_amt,
      c.c_customer_id
   FROM sampled_cs cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN store_sales ss ON ss.ss_ticket_number = cs.cs_order_number
   JOIN store_returns sr ON sr.sr_ticket_number = cs.cs_order_number
   JOIN web_site ws ON ws.web_open_date_sk = cs.cs_sold_date_sk
   JOIN date_dim d2 ON cp.cp_end_date_sk = d2.d_date_sk
   JOIN time_dim t2 ON sr.sr_return_time_sk = t2.t_time_sk
),
agg_main AS (
   SELECT
      cp_department,
      d_year,
      t_hour,
      cd_gender,
      hd_income_band_sk,
      SUM(ss_net_paid) AS total_net_paid,
      SUM(sr_return_amt) AS total_return_amt,
      COUNT(DISTINCT c_customer_id) AS distinct_customers
   FROM base_join
   GROUP BY CUBE (cp_department, d_year, t_hour, cd_gender, hd_income_band_sk)
   HAVING SUM(ss_net_paid) > 0
),
agg_exclude AS (
   SELECT
      cp_department,
      d_year,
      t_hour,
      cd_gender,
      hd_income_band_sk,
      SUM(ss_net_paid) AS total_net_paid,
      SUM(sr_return_amt) AS total_return_amt,
      COUNT(DISTINCT c_customer_id) AS distinct_customers
   FROM base_join
   WHERE sr_return_amt > 1000
   GROUP BY CUBE (cp_department, d_year, t_hour, cd_gender, hd_income_band_sk)
   HAVING SUM(ss_net_paid) > 0
)
SELECT
   ROW_NUMBER() OVER (ORDER BY d_year, cp_department) AS row_num,
   cp_department,
   d_year,
   t_hour,
   cd_gender,
   hd_income_band_sk,
   total_net_paid,
   total_return_amt,
   distinct_customers
FROM (
   SELECT * FROM agg_main
   EXCEPT
   SELECT * FROM agg_exclude
) AS final_set
ORDER BY d_year, cp_department
LIMIT 100

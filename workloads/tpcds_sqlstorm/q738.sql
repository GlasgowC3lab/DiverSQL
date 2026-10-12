WITH store_sales_agg AS (
  SELECT
    ss_customer_sk AS cust_sk,
    d.d_year AS sales_year,
    d.d_month_seq AS month_seq,
    SUM(ss_net_paid) AS net_paid,
    SUM(ss_net_profit) AS net_profit,
    SUM(ss_ext_discount_amt) AS discount
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
  GROUP BY ss_customer_sk, d.d_year, d.d_month_seq
),
catalog_sales_agg AS (
  SELECT
    cs_bill_customer_sk AS cust_sk,
    d.d_year AS sales_year,
    d.d_month_seq AS month_seq,
    SUM(cs_net_paid) AS net_paid,
    SUM(cs_net_profit) AS net_profit,
    SUM(cs_ext_discount_amt) AS discount
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
  GROUP BY cs_bill_customer_sk, d.d_year, d.d_month_seq
),
web_sales_agg AS (
  SELECT
    ws_bill_customer_sk AS cust_sk,
    d.d_year AS sales_year,
    d.d_month_seq AS month_seq,
    SUM(ws_net_paid) AS net_paid,
    SUM(ws_net_profit) AS net_profit,
    SUM(ws_ext_discount_amt) AS discount
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
  GROUP BY ws_bill_customer_sk, d.d_year, d.d_month_seq
),
all_sales AS (
  SELECT cust_sk, sales_year, month_seq, net_paid, net_profit, discount FROM store_sales_agg
  UNION ALL
  SELECT cust_sk, sales_year, month_seq, net_paid, net_profit, discount FROM catalog_sales_agg
  UNION ALL
  SELECT cust_sk, sales_year, month_seq, net_paid, net_profit, discount FROM web_sales_agg
),
combined_sales AS (
  SELECT
    cust_sk,
    sales_year,
    month_seq,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    SUM(discount) AS total_discount
  FROM all_sales
  GROUP BY cust_sk, sales_year, month_seq
),
customer_demo AS (
  SELECT cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
  FROM customer_demographics
),
customer_info AS (
  SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
  FROM customer c
  LEFT JOIN customer_demo cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ranked_sales AS (
  SELECT
    cs.sales_year,
    cs.month_seq,
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    cs.total_net_paid,
    cs.total_net_profit,
    cs.total_discount,
    ROW_NUMBER() OVER (PARTITION BY cs.sales_year, cs.month_seq ORDER BY cs.total_net_paid DESC) AS rank_in_month
  FROM combined_sales cs
  JOIN customer_info ci ON cs.cust_sk = ci.c_customer_sk
),
cumulative_sales AS (
  SELECT
    rs.*,
    SUM(total_net_paid) OVER (PARTITION BY c_customer_sk ORDER BY sales_year, month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_paid
  FROM ranked_sales rs
)
SELECT
  sales_year,
  month_seq,
  c_customer_sk,
  c_first_name,
  c_last_name,
  cd_gender,
  cd_marital_status,
  cd_education_status,
  total_net_paid,
  total_net_profit,
  total_discount,
  cum_net_paid,
  rank_in_month
FROM cumulative_sales
WHERE rank_in_month <= 10
ORDER BY sales_year, month_seq, rank_in_month

WITH latest_year AS (
  SELECT MAX(d_year) AS y FROM date_dim
),
store_agg AS (
  SELECT 
    ss_customer_sk,
    d_year,
    d_month_seq,
    SUM(ss_net_profit) AS store_net_profit,
    SUM(ss_quantity) AS store_quantity,
    COUNT(DISTINCT ss_ticket_number) AS store_transactions
  FROM store_sales
  JOIN date_dim ON ss_sold_date_sk = d_date_sk
  WHERE d_year = (SELECT y FROM latest_year)
  GROUP BY ss_customer_sk, d_year, d_month_seq
),
catalog_agg AS (
  SELECT 
    cs_bill_customer_sk AS customer_sk,
    d_year,
    d_month_seq,
    SUM(cs_net_profit) AS catalog_net_profit,
    SUM(cs_quantity) AS catalog_quantity,
    COUNT(DISTINCT cs_order_number) AS catalog_transactions
  FROM catalog_sales
  JOIN date_dim ON cs_sold_date_sk = d_date_sk
  WHERE d_year = (SELECT y FROM latest_year)
  GROUP BY cs_bill_customer_sk, d_year, d_month_seq
),
web_agg AS (
  SELECT
    ws_bill_customer_sk AS customer_sk,
    d_year,
    d_month_seq,
    SUM(ws_net_profit) AS web_net_profit,
    SUM(ws_quantity) AS web_quantity,
    COUNT(DISTINCT ws_order_number) AS web_transactions
  FROM web_sales
  JOIN date_dim ON ws_sold_date_sk = d_date_sk
  WHERE d_year = (SELECT y FROM latest_year)
  GROUP BY ws_bill_customer_sk, d_year, d_month_seq
),
combined AS (
  SELECT 
    COALESCE(s.ss_customer_sk, c.customer_sk, w.customer_sk) AS customer_sk,
    COALESCE(s.d_month_seq, c.d_month_seq, w.d_month_seq) AS month_seq,
    COALESCE(s.store_net_profit,0) + COALESCE(c.catalog_net_profit,0) + COALESCE(w.web_net_profit,0) AS total_net_profit,
    COALESCE(s.store_quantity,0) + COALESCE(c.catalog_quantity,0) + COALESCE(w.web_quantity,0) AS total_quantity,
    COALESCE(s.store_transactions,0) + COALESCE(c.catalog_transactions,0) + COALESCE(w.web_transactions,0) AS total_transactions
  FROM store_agg s
  FULL OUTER JOIN catalog_agg c 
    ON s.ss_customer_sk = c.customer_sk AND s.d_month_seq = c.d_month_seq
  FULL OUTER JOIN web_agg w
    ON COALESCE(s.ss_customer_sk,c.customer_sk) = w.customer_sk AND COALESCE(s.d_month_seq,c.d_month_seq) = w.d_month_seq
),
sales_dates AS (
  SELECT 
    customer_sk,
    MIN(d_date) AS first_sale_date,
    MAX(d_date) AS last_sale_date
  FROM (
    SELECT ss_customer_sk AS customer_sk, d_date
    FROM store_sales ss
    JOIN date_dim d ON ss_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT cs_bill_customer_sk AS customer_sk, d_date
    FROM catalog_sales cs
    JOIN date_dim d ON cs_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT ws_bill_customer_sk AS customer_sk, d_date
    FROM web_sales ws
    JOIN date_dim d ON ws_sold_date_sk = d.d_date_sk
  ) t
  GROUP BY customer_sk
),
customer_enriched AS (
  SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(comb.total_net_profit) AS year_net_profit,
    SUM(comb.total_quantity) AS year_quantity,
    SUM(comb.total_transactions) AS year_transactions,
    date_diff('day', sd.first_sale_date, sd.last_sale_date) AS active_days,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(comb.total_net_profit) DESC) AS gender_rank,
    ROW_NUMBER() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY SUM(comb.total_net_profit) DESC) AS income_band_rank
  FROM combined comb
  JOIN customer c ON comb.customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN sales_dates sd ON c.c_customer_sk = sd.customer_sk
  GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, hd.hd_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, sd.first_sale_date, sd.last_sale_date
),
top_customers AS (
  SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    c.hd_income_band_sk,
    c.ib_lower_bound,
    c.ib_upper_bound,
    c.year_net_profit,
    c.year_quantity,
    c.year_transactions,
    c.active_days,
    c.gender_rank,
    c.income_band_rank
  FROM customer_enriched c
  WHERE c.gender_rank <= 5 OR c.income_band_rank <= 5
)
SELECT 
  tc.c_customer_sk,
  tc.c_first_name,
  tc.c_last_name,
  tc.cd_gender,
  tc.cd_marital_status,
  tc.cd_education_status,
  tc.hd_income_band_sk,
  tc.ib_lower_bound,
  tc.ib_upper_bound,
  tc.year_net_profit,
  tc.year_quantity,
  tc.year_transactions,
  tc.active_days,
  tc.gender_rank,
  tc.income_band_rank,
  CASE 
    WHEN tc.gender_rank = 1 THEN 'Top Gender'
    WHEN tc.income_band_rank = 1 THEN 'Top Income'
    ELSE 'Other'
  END AS segment_type
FROM top_customers tc
ORDER BY tc.year_net_profit DESC
LIMIT 100

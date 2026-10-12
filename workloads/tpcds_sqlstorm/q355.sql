WITH cat_sales AS (
    SELECT cs_bill_customer_sk AS cust_sk,
           SUM(cs_net_paid) AS cat_net_paid,
           SUM(cs_ext_discount_amt) AS cat_total_discount,
           COUNT(*) AS cat_order_cnt,
           MAX(cs_sold_date_sk) AS cat_last_sold_sk
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 365 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY cs_bill_customer_sk
),
store_sales_agg AS (
    SELECT ss_customer_sk AS cust_sk,
           SUM(ss_net_paid) AS store_net_paid,
           SUM(ss_ext_discount_amt) AS store_total_discount,
           COUNT(*) AS store_order_cnt,
           MAX(ss_sold_date_sk) AS store_last_sold_sk
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 365 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ss_customer_sk
),
web_sales_agg AS (
    SELECT ws_bill_customer_sk AS cust_sk,
           SUM(ws_net_paid) AS web_net_paid,
           SUM(ws_ext_discount_amt) AS web_total_discount,
           COUNT(*) AS web_order_cnt,
           MAX(ws_sold_date_sk) AS web_last_sold_sk
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 365 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws_bill_customer_sk
),
combined_sales AS (
    SELECT COALESCE(cat.cust_sk, s.cust_sk, w.cust_sk) AS cust_sk,
           COALESCE(cat.cat_net_paid, 0) AS cat_net_paid,
           COALESCE(s.store_net_paid, 0) AS store_net_paid,
           COALESCE(w.web_net_paid, 0) AS web_net_paid,
           COALESCE(cat.cat_total_discount, 0) AS cat_total_discount,
           COALESCE(s.store_total_discount, 0) AS store_total_discount,
           COALESCE(w.web_total_discount, 0) AS web_total_discount,
           COALESCE(cat.cat_order_cnt, 0) AS cat_order_cnt,
           COALESCE(s.store_order_cnt, 0) AS store_order_cnt,
           COALESCE(w.web_order_cnt, 0) AS web_order_cnt,
           GREATEST(COALESCE(cat.cat_last_sold_sk, 0),
                    COALESCE(s.store_last_sold_sk, 0),
                    COALESCE(w.web_last_sold_sk, 0)) AS last_sold_sk
    FROM cat_sales cat
    FULL OUTER JOIN store_sales_agg s ON cat.cust_sk = s.cust_sk
    FULL OUTER JOIN web_sales_agg w ON COALESCE(cat.cust_sk, s.cust_sk) = w.cust_sk
),
customer_info AS (
    SELECT c.c_customer_sk AS cust_sk,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
           c.c_preferred_cust_flag,
           COALESCE(cd.cd_gender, 'U') AS gender,
           COALESCE(cd.cd_marital_status, 'U') AS marital_status,
           COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential,
           COALESCE(ib.ib_lower_bound, 0) AS income_lower,
           COALESCE(ib.ib_upper_bound, 0) AS income_upper
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
last_purchase_date AS (
    SELECT d.d_date_sk,
           d.d_date
    FROM date_dim d
),
top_customers AS (
    SELECT cs.cust_sk,
           ci.full_name,
           ci.c_preferred_cust_flag,
           ci.gender,
           ci.marital_status,
           ci.buy_potential,
           CONCAT(CAST(ci.income_lower AS VARCHAR), '-', CAST(ci.income_upper AS VARCHAR)) AS income_range,
           cs.cat_net_paid,
           cs.store_net_paid,
           cs.web_net_paid,
           (cs.cat_net_paid + cs.store_net_paid + cs.web_net_paid) AS total_net_paid,
           cs.cat_total_discount,
           cs.store_total_discount,
           cs.web_total_discount,
           (cs.cat_total_discount + cs.store_total_discount + cs.web_total_discount) AS total_discount,
           cs.cat_order_cnt,
           cs.store_order_cnt,
           cs.web_order_cnt,
           (cs.cat_order_cnt + cs.store_order_cnt + cs.web_order_cnt) AS total_orders,
           lpd.d_date AS last_purchase_date,
           ROW_NUMBER() OVER (ORDER BY (cs.cat_net_paid + cs.store_net_paid + cs.web_net_paid) DESC) AS sales_rank,
           CASE 
               WHEN (cs.cat_total_discount + cs.store_total_discount + cs.web_total_discount) > ((cs.cat_net_paid + cs.store_net_paid + cs.web_net_paid) * 0.1) THEN 'HIGH_DISCOUNT'
               ELSE 'NORMAL'
           END AS discount_category,
           COALESCE(
               NULLIF((cs.cat_net_paid + cs.store_net_paid + cs.web_net_paid),0) / NULLIF((cs.cat_order_cnt + cs.store_order_cnt + cs.web_order_cnt),0),
               0) AS avg_net_per_order,
           CASE 
               WHEN cs.last_sold_sk IS NULL THEN FALSE
               ELSE TRUE
           END AS has_recent_purchase
    FROM combined_sales cs
    JOIN customer_info ci ON cs.cust_sk = ci.cust_sk
    LEFT JOIN last_purchase_date lpd ON cs.last_sold_sk = lpd.d_date_sk
)
SELECT *
FROM top_customers
WHERE sales_rank <= 100
UNION ALL
SELECT
   -1,
   'ALL CUSTOMERS',
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   SUM(cs.cat_net_paid),
   SUM(cs.store_net_paid),
   SUM(cs.web_net_paid),
   SUM(cs.cat_net_paid + cs.store_net_paid + cs.web_net_paid),
   SUM(cs.cat_total_discount),
   SUM(cs.store_total_discount),
   SUM(cs.web_total_discount),
   SUM(cs.cat_total_discount + cs.store_total_discount + cs.web_total_discount),
   SUM(cs.cat_order_cnt),
   SUM(cs.store_order_cnt),
   SUM(cs.web_order_cnt),
   SUM(cs.cat_order_cnt + cs.store_order_cnt + cs.web_order_cnt),
   NULL,
   NULL,
   NULL,
   NULL,
   NULL
FROM combined_sales cs
ORDER BY (sales_rank IS NULL), sales_rank, total_net_paid DESC

WITH store_sales_raw AS (
    SELECT ss.ss_customer_sk AS customer_sk,
           ss.ss_ticket_number AS order_number,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_net_paid AS net_paid,
           ss.ss_promo_sk AS promo_sk,
           'store' AS channel
    FROM store_sales ss
),
catalog_sales_raw AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk,
           cs.cs_order_number AS order_number,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_promo_sk AS promo_sk,
           'catalog' AS channel
    FROM catalog_sales cs
),
web_sales_raw AS (
    SELECT ws.ws_bill_customer_sk AS customer_sk,
           ws.ws_order_number AS order_number,
           ws.ws_sold_date_sk AS date_sk,
           ws.ws_net_paid AS net_paid,
           ws.ws_promo_sk AS promo_sk,
           'web' AS channel
    FROM web_sales ws
),
sales_by_channel AS (
    SELECT * FROM store_sales_raw
    UNION ALL
    SELECT * FROM catalog_sales_raw
    UNION ALL
    SELECT * FROM web_sales_raw
),
sales_filtered AS (
    SELECT s.*,
           d.d_year,
           COALESCE(p.p_promo_name, 'No Promo') AS promo_name
    FROM sales_by_channel s
    LEFT JOIN date_dim d ON s.date_sk = d.d_date_sk
    LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
    WHERE d.d_year IN (2001, 2002) OR d.d_year IS NULL
),
customer_agg AS (
    SELECT sf.customer_sk,
           c.c_first_name,
           c.c_last_name,
           COALESCE(c.c_preferred_cust_flag, 'N') AS pref_flag,
           cd.cd_gender,
           cd.cd_marital_status,
           SUM(sf.net_paid) AS total_sales,
           COUNT(DISTINCT sf.date_sk) AS sales_days,
           COUNT(DISTINCT sf.order_number) AS distinct_orders,
           MAX(sf.net_paid) AS max_single_sale,
           AVG(sf.net_paid) AS avg_sale,
           MIN(CASE WHEN sf.net_paid IS NOT NULL THEN sf.net_paid END) AS min_sale,
           SUM(CASE WHEN sf.channel = 'store' THEN 1 ELSE 0 END) AS store_sales_cnt,
           SUM(CASE WHEN sf.channel = 'catalog' THEN 1 ELSE 0 END) AS catalog_sales_cnt,
           SUM(CASE WHEN sf.channel = 'web' THEN 1 ELSE 0 END) AS web_sales_cnt,
           COUNT(DISTINCT sf.channel) AS channel_count
    FROM sales_filtered sf
    LEFT JOIN customer c ON c.c_customer_sk = sf.customer_sk
    LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY sf.customer_sk,
             c.c_first_name,
             c.c_last_name,
             COALESCE(c.c_preferred_cust_flag, 'N'),
             cd.cd_gender,
             cd.cd_marital_status
),
ranked_customers AS (
    SELECT ca.*,
           ROW_NUMBER() OVER (PARTITION BY ca.cd_gender ORDER BY ca.total_sales DESC) AS gender_rank,
           RANK() OVER (ORDER BY ca.total_sales DESC) AS overall_rank,
           CONCAT(ca.c_first_name, ' ', ca.c_last_name) AS full_name
    FROM customer_agg ca
),
sales_by_year AS (
    SELECT sf.customer_sk,
           SUM(CASE WHEN d.d_year = 2002 THEN sf.net_paid ELSE 0 END) AS sales_2002,
           SUM(CASE WHEN d.d_year = 2001 THEN sf.net_paid ELSE 0 END) AS sales_2001,
           MAX(d.d_date) AS last_sale_date
    FROM sales_filtered sf
    LEFT JOIN date_dim d ON sf.date_sk = d.d_date_sk
    GROUP BY sf.customer_sk
),
store_customers AS (
    SELECT DISTINCT customer_sk FROM store_sales_raw
),
catalog_customers AS (
    SELECT DISTINCT customer_sk FROM catalog_sales_raw
),
web_customers AS (
    SELECT DISTINCT customer_sk FROM web_sales_raw
),
customers_all_channels AS (
    SELECT customer_sk FROM store_customers
    INTERSECT
    SELECT customer_sk FROM catalog_customers
    INTERSECT
    SELECT customer_sk FROM web_customers
),
customers_no_negative AS (
    SELECT rc.*
    FROM ranked_customers rc
    WHERE NOT EXISTS (
        SELECT 1
        FROM sales_filtered sf
        WHERE sf.customer_sk = rc.customer_sk
          AND sf.net_paid < 0
    )
)
SELECT rc.full_name,
       rc.pref_flag,
       rc.cd_gender,
       rc.cd_marital_status,
       rc.total_sales,
       rc.sales_days,
       rc.distinct_orders,
       rc.max_single_sale,
       rc.avg_sale,
       rc.store_sales_cnt,
       rc.catalog_sales_cnt,
       rc.web_sales_cnt,
       COALESCE(sby.sales_2002, 0) - COALESCE(sby.sales_2001, 0) AS sales_change_2002_vs_2001,
       rc.overall_rank,
       rc.gender_rank,
       CASE
           WHEN rc.total_sales > 100000 THEN 'Platinum'
           WHEN rc.total_sales > 50000 THEN 'Gold'
           WHEN rc.total_sales > 20000 THEN 'Silver'
           ELSE 'Bronze'
       END AS tier,
       (SELECT COUNT(*)
        FROM sales_filtered sbc
        WHERE sbc.customer_sk = rc.customer_sk
          AND sbc.net_paid > 5000) AS high_value_orders,
       rc.channel_count,
       COALESCE(sby.last_sale_date, DATE '1970-01-01') AS last_sale_date,
       CASE WHEN EXISTS (
           SELECT 1 FROM sales_filtered sf2
           WHERE sf2.customer_sk = rc.customer_sk
             AND sf2.promo_name <> 'No Promo'
       ) THEN 'Promo Used' ELSE 'No Promo' END AS promo_usage_flag
FROM customers_no_negative rc
LEFT JOIN sales_by_year sby ON rc.customer_sk = sby.customer_sk
WHERE rc.overall_rank <= 10
  AND rc.customer_sk IN (SELECT customer_sk FROM customers_all_channels)
ORDER BY rc.overall_rank

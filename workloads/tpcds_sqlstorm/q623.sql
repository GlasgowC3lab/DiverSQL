WITH
sales_union AS (
   SELECT
       ss_sold_date_sk AS date_sk,
       ss_customer_sk AS cust_sk,
       ss_net_paid AS net_paid,
       ss_net_paid_inc_tax AS net_paid_inc_tax,
       ss_net_profit AS net_profit,
       ss_quantity AS quantity,
       ss_item_sk AS item_sk,
       'store' AS sales_channel
   FROM store_sales
   UNION ALL
   SELECT
       cs_sold_date_sk,
       cs_bill_customer_sk,
       cs_net_paid,
       cs_net_paid_inc_tax,
       cs_net_profit,
       cs_quantity,
       cs_item_sk,
       'catalog'
   FROM catalog_sales
   UNION ALL
   SELECT
       ws_sold_date_sk,
       ws_bill_customer_sk,
       ws_net_paid,
       ws_net_paid_inc_tax,
       ws_net_profit,
       ws_quantity,
       ws_item_sk,
       'web'
   FROM web_sales
),
returns_union AS (
   SELECT
       sr_returned_date_sk AS date_sk,
       sr_customer_sk AS cust_sk,
       sr_return_amt AS return_amount,
       sr_return_quantity AS return_quantity,
       'store' AS return_channel
   FROM store_returns
   UNION ALL
   SELECT
       cr_returned_date_sk,
       cr_returning_customer_sk,
       cr_return_amount,
       cr_return_quantity,
       'catalog'
   FROM catalog_returns
   UNION ALL
   SELECT
       wr_returned_date_sk,
       wr_refunded_customer_sk,
       wr_return_amt,
       wr_return_quantity,
       'web'
   FROM web_returns
),
sales_agg AS (
   SELECT
       su.cust_sk,
       d.d_year,
       d.d_quarter_name,
       SUM(su.net_paid) AS total_net_paid,
       SUM(su.net_paid_inc_tax) AS total_net_paid_inc_tax,
       SUM(su.net_profit) AS total_net_profit,
       SUM(su.quantity) AS total_quantity,
       MAX(su.date_sk) AS latest_sales_date_sk,
       COUNT(DISTINCT su.sales_channel) AS sales_channels,
       SUM(su.net_paid) * COALESCE(SUM(su.quantity), 1) / NULLIF(SUM(su.net_paid), 0) AS weird_factor
   FROM sales_union su
   LEFT JOIN date_dim d ON su.date_sk = d.d_date_sk
   GROUP BY su.cust_sk, d.d_year, d.d_quarter_name
),
returns_agg AS (
   SELECT
       ru.cust_sk,
       d.d_year,
       d.d_quarter_name,
       SUM(ru.return_amount) AS total_return_amount,
       SUM(ru.return_quantity) AS total_return_quantity
   FROM returns_union ru
   LEFT JOIN date_dim d ON ru.date_sk = d.d_date_sk
   GROUP BY ru.cust_sk, d.d_year, d.d_quarter_name
),
final_agg AS (
   SELECT
       COALESCE(sa.cust_sk, ra.cust_sk) AS cust_sk,
       COALESCE(sa.d_year, ra.d_year) AS d_year,
       COALESCE(sa.d_quarter_name, ra.d_quarter_name) AS d_quarter_name,
       sa.total_net_paid,
       sa.total_net_paid_inc_tax,
       sa.total_net_profit,
       sa.total_quantity,
       sa.latest_sales_date_sk,
       sa.sales_channels,
       sa.weird_factor,
       ra.total_return_amount,
       ra.total_return_quantity
   FROM sales_agg sa
   FULL OUTER JOIN returns_agg ra
       ON sa.cust_sk = ra.cust_sk
          AND sa.d_year = ra.d_year
          AND sa.d_quarter_name = ra.d_quarter_name
),
customer_info AS (
   SELECT
       c.c_customer_sk,
       COALESCE(c.c_first_name, '') AS c_first_name,
       COALESCE(c.c_last_name, '') AS c_last_name,
       c.c_email_address,
       c.c_birth_day,
       c.c_birth_month,
       c.c_birth_year,
       cd.cd_gender,
       cd.cd_marital_status,
       cd.cd_education_status,
       hd.hd_income_band_sk,
       hd.hd_buy_potential,
       COALESCE(c.c_preferred_cust_flag, 'N') AS pref_flag,
       CONCAT(UPPER(c.c_first_name), ' ', UPPER(c.c_last_name)) AS full_name_upper,
       CASE WHEN c.c_email_address LIKE '%@%' THEN regexp_extract(c.c_email_address, '@([^@]+)$', 1) ELSE NULL END AS email_domain,
       CASE WHEN c.c_email_address IS NULL THEN 'UNKNOWN' ELSE c.c_email_address END AS email_normalized
   FROM customer c
   LEFT JOIN customer_demographics cd
       ON (c.c_current_cdemo_sk = cd.cd_demo_sk OR (c.c_current_cdemo_sk IS NULL AND cd.cd_demo_sk IS NULL))
   LEFT JOIN household_demographics hd
       ON hd.hd_demo_sk = cd.cd_demo_sk + 1
),
enriched AS (
   SELECT
       fa.cust_sk,
       ci.full_name_upper,
       ci.email_normalized,
       fa.d_year,
       fa.d_quarter_name,
       fa.total_net_paid,
       fa.total_return_amount,
       (COALESCE(fa.total_net_profit, 0) - COALESCE(fa.total_return_amount, 0)) AS adj_net_profit,
       CASE WHEN COALESCE(fa.total_net_paid, 0) = 0 THEN NULL
            ELSE (COALESCE(fa.total_net_profit, 0) - COALESCE(fa.total_return_amount, 0)) / COALESCE(fa.total_net_paid, 0) END AS profit_margin,
       (SELECT MAX(d.d_date) FROM date_dim d WHERE d.d_date_sk = fa.latest_sales_date_sk) AS latest_purchase_date,
       ROW_NUMBER() OVER (PARTITION BY fa.d_year, fa.d_quarter_name ORDER BY (COALESCE(fa.total_net_profit, 0) - COALESCE(fa.total_return_amount, 0)) DESC) AS profit_rank,
       CASE WHEN COALESCE(fa.total_return_quantity, 0) > COALESCE(fa.total_quantity, 0) THEN 1 ELSE 0 END AS excessive_returns_flag,
       fa.weird_factor,
       length(ci.email_domain) AS email_domain_len,
       CASE WHEN NULLIF(ci.pref_flag, 'N') IS NOT NULL THEN true ELSE false END AS is_preferred_customer,
       MOD(CAST(fa.weird_factor * 1000 AS BIGINT), 7) AS weird_modulo,
       SUM(COALESCE(fa.total_net_profit, 0) - COALESCE(fa.total_return_amount, 0)) OVER (PARTITION BY fa.d_year, fa.d_quarter_name) AS quarter_adj_net_profit_total
   FROM final_agg fa
   LEFT JOIN customer_info ci ON ci.c_customer_sk = fa.cust_sk
   WHERE ci.email_domain IS NOT NULL
     AND REGEXP_LIKE(ci.email_domain, '^.+\.com$')
     AND MOD(LENGTH(ci.email_domain) + CAST(COALESCE(fa.weird_factor, 0) * 10 AS INTEGER), 2) = 0
)

SELECT *
FROM enriched
WHERE profit_rank <= 10

UNION ALL

SELECT *
FROM enriched
WHERE total_net_paid IS NULL
  AND total_return_amount > 0
  AND profit_rank IS NULL

WITH
store_sales_agg AS (
  SELECT
    ss_customer_sk AS customer_sk,
    SUM(ss_net_profit) AS store_net_profit,
    SUM(ss_quantity) AS store_quantity,
    MAX(date_dim.d_date) AS last_store_sale_date,
    COUNT(DISTINCT ss_store_sk) AS distinct_store_cnt
  FROM store_sales
  LEFT JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
  GROUP BY ss_customer_sk
),
catalog_sales_agg AS (
  SELECT
    cs_bill_customer_sk AS customer_sk,
    SUM(cs_net_profit) AS catalog_net_profit,
    SUM(cs_quantity) AS catalog_quantity,
    MAX(date_dim.d_date) AS last_catalog_sale_date,
    COUNT(DISTINCT cs_catalog_page_sk) AS distinct_catalog_page_cnt,
    MAX(p.p_discount_active) AS any_active_promo_flag
  FROM catalog_sales
  LEFT JOIN date_dim ON catalog_sales.cs_sold_date_sk = date_dim.d_date_sk
  LEFT JOIN promotion p ON cs_promo_sk = p.p_promo_sk
  GROUP BY cs_bill_customer_sk
),
web_sales_agg AS (
  SELECT
    ws_bill_customer_sk AS customer_sk,
    SUM(ws_net_profit) AS web_net_profit,
    SUM(ws_quantity) AS web_quantity,
    MAX(date_dim.d_date) AS last_web_sale_date,
    COUNT(DISTINCT ws_web_page_sk) AS distinct_web_page_cnt,
    MAX(p.p_discount_active) AS any_active_promo_flag_web
  FROM web_sales
  LEFT JOIN date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
  LEFT JOIN promotion p ON ws_promo_sk = p.p_promo_sk
  GROUP BY ws_bill_customer_sk
),
customer_info AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    concat_ws(' ', c.c_first_name, c.c_last_name) AS full_name,
    c.c_preferred_cust_flag,
    cd.cd_gender,
    cd.cd_marital_status,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip
  FROM customer c
  LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
customers_with_returns AS (
  SELECT DISTINCT sr_customer_sk AS customer_sk FROM store_returns
  UNION
  SELECT DISTINCT cr_returning_customer_sk FROM catalog_returns
  UNION
  SELECT DISTINCT wr_returning_customer_sk FROM web_returns
),
customers_book_category AS (
  SELECT DISTINCT cs.cs_bill_customer_sk AS customer_sk
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE i.i_category = 'Books'
  UNION
  SELECT DISTINCT ss.ss_customer_sk AS customer_sk
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE i.i_category = 'Books'
  UNION
  SELECT DISTINCT ws.ws_bill_customer_sk AS customer_sk
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE i.i_category = 'Books'
),
combined_sales AS (
  SELECT
    ci.c_customer_sk,
    ci.c_customer_id,
    ci.full_name,
    ci.c_preferred_cust_flag,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip,
    COALESCE(ssa.store_net_profit, 0) AS store_net_profit,
    COALESCE(ssa.store_quantity, 0) AS store_quantity,
    COALESCE(csa.catalog_net_profit, 0) AS catalog_net_profit,
    COALESCE(csa.catalog_quantity, 0) AS catalog_quantity,
    COALESCE(wsa.web_net_profit, 0) AS web_net_profit,
    COALESCE(wsa.web_quantity, 0) AS web_quantity,
    (COALESCE(ssa.store_net_profit, 0) + COALESCE(csa.catalog_net_profit, 0) + COALESCE(wsa.web_net_profit, 0)) AS total_net_profit,
    (COALESCE(ssa.store_quantity, 0) + COALESCE(csa.catalog_quantity, 0) + COALESCE(wsa.web_quantity, 0)) AS total_quantity,
    GREATEST(COALESCE(ssa.last_store_sale_date, DATE '1970-01-01'), COALESCE(csa.last_catalog_sale_date, DATE '1970-01-01'), COALESCE(wsa.last_web_sale_date, DATE '1970-01-01')) AS most_recent_sale_date,
    CASE
      WHEN COALESCE(ssa.store_net_profit, 0) > 0 AND COALESCE(csa.catalog_net_profit, 0) > 0 AND COALESCE(wsa.web_net_profit, 0) > 0 THEN 'Omni'
      WHEN COALESCE(ssa.store_net_profit, 0) > 0 THEN 'Store'
      WHEN COALESCE(csa.catalog_net_profit, 0) > 0 THEN 'Catalog'
      WHEN COALESCE(wsa.web_net_profit, 0) > 0 THEN 'Web'
      ELSE 'None'
    END AS channel_profile,
    CASE
      WHEN COALESCE(csa.any_active_promo_flag, 'N') = 'Y' OR COALESCE(wsa.any_active_promo_flag_web, 'N') = 'Y' THEN 1 ELSE 0 END AS has_active_promo
  FROM customer_info ci
  LEFT JOIN store_sales_agg ssa ON ci.c_customer_sk = ssa.customer_sk
  LEFT JOIN catalog_sales_agg csa ON ci.c_customer_sk = csa.customer_sk
  LEFT JOIN web_sales_agg wsa ON ci.c_customer_sk = wsa.customer_sk
),
ranked_customers AS (
  SELECT
    cs.c_customer_sk,
    cs.c_customer_id,
    cs.full_name,
    cs.c_preferred_cust_flag,
    NULLIF(cs.c_preferred_cust_flag, 'N') AS preferred_flag_normalized,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.ca_city,
    cs.ca_state,
    cs.ca_zip,
    cs.store_net_profit,
    cs.catalog_net_profit,
    cs.web_net_profit,
    cs.total_net_profit,
    cs.total_quantity,
    cs.most_recent_sale_date,
    cs.channel_profile,
    cs.has_active_promo,
    CASE WHEN cwr.customer_sk IS NOT NULL THEN 1 ELSE 0 END AS has_returns,
    CASE WHEN cbc.customer_sk IS NOT NULL THEN 1 ELSE 0 END AS bought_books_category,
    CASE WHEN cs.total_quantity <> 0 THEN cs.total_net_profit / cs.total_quantity ELSE NULL END AS profit_per_quantity,
    concat('Customer ', cs.full_name, ' (ID=', cs.c_customer_id, ')') AS customer_label,
    regexp_replace(cs.ca_city, '[^A-Za-z0-9]', '_') AS city_sanitized,
    CASE WHEN EXISTS (SELECT 1 FROM store_sales ss2 WHERE ss2.ss_customer_sk = cs.c_customer_sk AND ss2.ss_quantity > 10) THEN 1 ELSE 0 END AS has_high_quantity_store_sales,
    RANK() OVER (ORDER BY cs.total_net_profit DESC NULLS LAST) AS total_profit_rank,
    DENSE_RANK() OVER (ORDER BY cs.total_net_profit DESC) AS dense_profit_rank,
    ROW_NUMBER() OVER (PARTITION BY cs.ca_state ORDER BY cs.total_net_profit DESC) AS row_num_state,
    SUM(cs.total_net_profit) OVER (ORDER BY cs.total_net_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_profit,
    (SELECT AVG(total_net_profit) FROM combined_sales cs2 WHERE cs2.cd_gender = cs.cd_gender) AS avg_profit_same_gender,
    (SELECT MAX(total_net_profit) FROM combined_sales cs3 WHERE cs3.ca_zip = cs.ca_zip) AS max_profit_same_zip,
    CASE
      WHEN cs.total_net_profit > 200000 THEN 'Platinum'
      WHEN cs.total_net_profit > 100000 THEN 'Gold'
      WHEN cs.total_net_profit > 50000 THEN 'Silver'
      ELSE 'Bronze'
    END AS profit_tier,
    CASE
      WHEN (cs.total_net_profit BETWEEN 0 AND 50000 OR cs.total_net_profit IS NULL) AND (cs.c_preferred_cust_flag = 'Y' OR cs.c_preferred_cust_flag IS NULL) THEN 'Candidate'
      ELSE 'Other'
    END AS candidate_flag
  FROM combined_sales cs
  LEFT JOIN customers_with_returns cwr ON cs.c_customer_sk = cwr.customer_sk
  LEFT JOIN customers_book_category cbc ON cs.c_customer_sk = cbc.customer_sk
),
top_customers AS (
  SELECT *
  FROM ranked_customers
  WHERE total_profit_rank <= 50
)
SELECT *
FROM top_customers
INTERSECT
SELECT *
FROM top_customers
WHERE has_returns = 0 AND has_active_promo = 1
ORDER BY total_profit_rank

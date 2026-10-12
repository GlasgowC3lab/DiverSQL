WITH sampled_sales AS (
    SELECT *
    FROM tpcds.store_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ss_quantity > 1
      AND ss_ext_sales_price > 100
),
joined_all AS (
    SELECT
        s.s_store_name,
        d.d_year,
        i.i_category,
        p.p_promo_name,
        ca.ca_state,
        c.c_preferred_cust_flag,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_paid
    FROM sampled_sales ss
    JOIN tpcds.date_dim d        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s           ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.item i            ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.promotion p       ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.customer c        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE s.s_country = 'United States'
      AND ca.ca_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
      AND d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND i.i_current_price > 20
),
grouped_sales AS (
    SELECT
        s_store_name,
        d_year,
        i_category,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS txn_cnt,
        AVG(ss_ext_sales_price) AS avg_sales
    FROM joined_all
    GROUP BY s_store_name, d_year, i_category
),
high_sales AS (
    SELECT s_store_name, d_year, i_category
    FROM grouped_sales
    WHERE total_sales > 20000
),
high_avg AS (
    SELECT s_store_name, d_year, i_category
    FROM grouped_sales
    WHERE avg_sales > 800
),
common_keys AS (
    SELECT s_store_name, d_year, i_category
    FROM high_sales
    INTERSECT
    SELECT s_store_name, d_year, i_category
    FROM high_avg
)
SELECT
    g.s_store_name,
    g.d_year,
    g.i_category,
    g.total_sales,
    g.total_discount,
    g.txn_cnt,
    g.avg_sales
FROM grouped_sales g
JOIN common_keys ck
  ON g.s_store_name = ck.s_store_name
  AND g.d_year = ck.d_year
  AND g.i_category = ck.i_category
ORDER BY g.total_sales DESC
LIMIT 100

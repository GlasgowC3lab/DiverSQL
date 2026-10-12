WITH sales_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_ext_discount_amt > 500
      AND cs_net_paid_inc_ship_tax > 1000
      AND cs_quantity >= 1
      AND cs_ship_mode_sk IS NOT NULL
      AND cs_item_sk IS NOT NULL
      AND cs_promo_sk IS NOT NULL
),
sales_agg AS (
    SELECT cs_call_center_sk,
           SUM(cs_ext_discount_amt) AS sum_discount,
           SUM(cs_net_paid) AS sum_net_paid,
           COUNT(*) AS sales_cnt
    FROM sales_sample
    GROUP BY cs_call_center_sk
),
cust_web_agg AS (
    SELECT c.c_customer_sk,
           c.c_last_name,
           COUNT(wp.wp_web_page_sk) AS page_cnt,
           SUM(wp.wp_link_count) AS total_links
    FROM customer c
    LEFT JOIN web_page wp
           ON wp.wp_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1960 AND 1980
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY c.c_customer_sk, c.c_last_name
)
SELECT
    cc.cc_name,
    cw.c_last_name,
    SUM(sa.sum_discount) AS total_discount,
    SUM(sa.sum_net_paid) AS total_net_paid,
    SUM(sa.sales_cnt) AS total_sales_cnt,
    SUM(cw.page_cnt) AS total_page_cnt,
    SUM(cw.total_links) AS total_links,
    RANK() OVER (ORDER BY SUM(sa.sum_net_paid) DESC) AS net_paid_rank,
    CASE
        WHEN SUM(sa.sum_discount) > 20000 THEN 'HIGH'
        WHEN SUM(sa.sum_discount) > 10000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS discount_level
FROM sales_agg sa
RIGHT JOIN call_center cc
    ON sa.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN sales_sample ss
    ON ss.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN customer cust
    ON cust.c_customer_sk = ss.cs_bill_customer_sk
LEFT JOIN cust_web_agg cw
    ON cw.c_customer_sk = cust.c_customer_sk
WHERE cc.cc_state = 'CA'
  AND cc.cc_gmt_offset BETWEEN -5.0 AND 5.0
  AND cc.cc_tax_percentage < 8.0
  AND cc.cc_employees > 50
  AND cc.cc_closed_date_sk IS NULL
  AND cc.cc_open_date_sk IS NOT NULL
GROUP BY CUBE (cc.cc_name, cw.c_last_name)
HAVING COUNT(*) >= 1
ORDER BY net_paid_rank, cc.cc_name
LIMIT 100

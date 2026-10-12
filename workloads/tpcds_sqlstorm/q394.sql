WITH sales_union AS (
    SELECT ss.ss_customer_sk AS cust_sk,
           d.d_year AS year,
           ss.ss_net_profit AS net_profit,
           ss.ss_ext_discount_amt AS discount_amt,
           ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    UNION ALL
    SELECT cs.cs_bill_customer_sk AS cust_sk,
           d.d_year AS year,
           cs.cs_net_profit AS net_profit,
           cs.cs_ext_discount_amt AS discount_amt,
           cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    UNION ALL
    SELECT ws.ws_bill_customer_sk AS cust_sk,
           d.d_year AS year,
           ws.ws_net_profit AS net_profit,
           ws.ws_ext_discount_amt AS discount_amt,
           ws.ws_item_sk AS item_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
cust_agg AS (
    SELECT cust_sk,
           year,
           SUM(net_profit) AS total_profit,
           SUM(discount_amt) AS total_discount,
           COUNT(*) AS txn_count
    FROM sales_union
    GROUP BY cust_sk, year
),
ranked_cust AS (
    SELECT ca.cust_sk,
           ca.year,
           ca.total_profit,
           ca.total_discount,
           ca.txn_count,
           ROW_NUMBER() OVER (PARTITION BY ca.year ORDER BY ca.total_profit DESC) AS profit_rank,
           RANK() OVER (PARTITION BY ca.year ORDER BY ca.total_discount DESC) AS discount_rank
    FROM cust_agg ca
),
top_customers AS (
    SELECT year, cust_sk
    FROM (
        SELECT ca.year,
               ca.cust_sk,
               ROW_NUMBER() OVER (PARTITION BY ca.year ORDER BY ca.total_profit DESC) AS rn
        FROM cust_agg ca
    ) t
    WHERE t.rn = 1
),
customer_info AS (
    SELECT c.c_customer_sk,
           CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
           c.c_preferred_cust_flag,
           c.c_birth_year,
           ca.ca_city,
           ca.ca_state
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
final_data AS (
    SELECT ci.c_customer_sk,
           ci.full_name,
           ci.c_preferred_cust_flag,
           ci.c_birth_year,
           ci.ca_city,
           ci.ca_state,
           rc.year,
           rc.total_profit,
           rc.total_discount,
           rc.txn_count,
           rc.profit_rank,
           rc.discount_rank,
           CASE
               WHEN rc.total_profit > 20000 THEN 'HIGH'
               WHEN rc.total_profit > 0 THEN 'MEDIUM'
               ELSE 'LOW'
           END AS profit_category,
           (SELECT AVG(su.discount_amt / NULLIF(su.net_profit, 0))
            FROM sales_union su
            WHERE su.cust_sk = ci.c_customer_sk) AS avg_discount_ratio,
           (tc.cust_sk IS NOT NULL) AS is_top_customer_of_year
    FROM customer_info ci
    LEFT JOIN ranked_cust rc
        ON ci.c_customer_sk = rc.cust_sk
    LEFT JOIN top_customers tc
        ON rc.year = tc.year AND rc.cust_sk = tc.cust_sk
    WHERE (ci.c_preferred_cust_flag = 'Y' OR ci.c_birth_year > 1960)
      AND (rc.profit_rank IS NULL OR rc.profit_rank <= 10)
)
SELECT *
FROM final_data
ORDER BY profit_category DESC, profit_rank, c_customer_sk
LIMIT 100

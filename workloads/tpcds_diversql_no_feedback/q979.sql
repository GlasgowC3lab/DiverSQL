WITH filtered_sales AS (
    SELECT
        ca.ca_state,
        ss.ss_customer_sk,
        ss.ss_net_profit,
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_street_number
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE REGEXP_LIKE(ca.ca_address_id, '^AAAA')
      AND ca.ca_city LIKE '%York%'
      AND SUBSTRING(ca.ca_street_number, 1, 1) = '8'
)
SELECT
    ca_state,
    COUNT(DISTINCT ss_customer_sk) AS unique_customers,
    SUM(ss_net_profit) AS total_profit,
    REGEXP_EXTRACT(MIN(ca_address_id), '(A{3})(.*)', 2) AS extracted_suffix
FROM filtered_sales
GROUP BY ca_state
HAVING NOT EXISTS (
    SELECT 1
    FROM store_sales ss2
    JOIN customer_address ca2 ON ss2.ss_addr_sk = ca2.ca_address_sk
    JOIN customer_demographics cd2 ON ss2.ss_cdemo_sk = cd2.cd_demo_sk
    WHERE ca2.ca_state = filtered_sales.ca_state
      AND cd2.cd_gender = 'M'
      AND cd2.cd_dep_count >= 3
)
ORDER BY total_profit DESC
LIMIT 20

-- Goal: Summarize net profit by store for sales to customers living in cities starting with "A" and stores whose name contains "Mart". The query demonstrates string handling (LIKE, REGEXP_LIKE, REGEXP_EXTRACT, SUBSTR, CONCAT), uses DISTINCT in a COUNT, compares a column to a scalar sub‑query, and returns the top 100 stores by profit.
WITH sales_data AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_tax_percentage,
        ss.ss_net_profit,
        ss.ss_customer_sk,
        ca.ca_city,
        td.t_hour
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
)
SELECT
    sd.s_store_id,
    CONCAT(sd.s_store_name, ' - ', sd.s_city) AS full_store_label,
    SUBSTR(sd.s_city, 1, 3) AS city_prefix,
    REGEXP_EXTRACT(sd.s_store_name, '(\\w+)$') AS store_name_suffix,
    SUM(sd.ss_net_profit) AS total_profit,
    COUNT(DISTINCT sd.ss_customer_sk) AS unique_customers,
    MAX(sd.t_hour) AS latest_hour_sold
FROM sales_data sd
WHERE
    sd.s_store_name LIKE '%Mart%'
    AND REGEXP_LIKE(sd.ca_city, '^A.*')
    AND sd.s_tax_percentage > (
        SELECT s_tax_percentage
        FROM store
        WHERE s_store_id = 'S001'
        LIMIT 1
    )
GROUP BY
    sd.s_store_id,
    sd.s_store_name,
    sd.s_city,
    sd.s_tax_percentage
ORDER BY total_profit DESC
LIMIT 100

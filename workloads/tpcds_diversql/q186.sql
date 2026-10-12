WITH filtered_sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        d.d_year AS year,
        ss.ss_net_profit,
        ss.ss_net_paid_inc_tax,
        regexp_extract(s.s_store_id, '[0-9]+') AS store_number,
        CASE
            WHEN ss.ss_net_profit > 1000 THEN 'High'
            WHEN ss.ss_net_profit > 0 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        substr(s.s_store_name, 1, 5) AS name_prefix,
        s.s_store_name || ' - ' || s.s_city AS store_full_desc
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND regexp_like(s.s_store_name, '(?i)mart')
      AND ca.ca_state LIKE 'CA%'
)
SELECT
    store_full_desc,
    store_number,
    profit_category,
    year,
    COUNT(*) AS sales_transactions,
    SUM(ss_net_profit) AS total_profit,
    AVG(ss_net_paid_inc_tax) AS avg_paid_inc_tax
FROM filtered_sales
GROUP BY
    store_full_desc,
    store_number,
    profit_category,
    year
ORDER BY total_profit DESC
LIMIT 100

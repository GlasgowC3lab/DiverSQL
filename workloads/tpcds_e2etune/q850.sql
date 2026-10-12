WITH store_agg AS (
    SELECT
        t.t_hour,
        ca.ca_country,
        c.c_birth_year,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ss.ss_ext_discount_amt) AS store_discount,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_customer_cnt
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_year BETWEEN 1950 AND 1970
      AND c.c_salutation = 'Mr.'
      AND ca.ca_country = 'United States'
      AND t.t_hour BETWEEN 9 AND 21
    GROUP BY t.t_hour, ca.ca_country, c.c_birth_year
),
web_agg AS (
    SELECT
        t.t_hour,
        ca.ca_country,
        c.c_birth_year,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(ws.ws_ext_discount_amt) AS web_discount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customer_cnt
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_year BETWEEN 1950 AND 1970
      AND c.c_salutation = 'Mr.'
      AND ca.ca_country = 'United States'
      AND t.t_hour BETWEEN 9 AND 21
    GROUP BY t.t_hour, ca.ca_country, c.c_birth_year
)
SELECT
    agg.t_hour,
    agg.ca_country,
    agg.c_birth_year,
    COALESCE(store_agg.store_profit, 0) + COALESCE(web_agg.web_profit, 0) AS total_profit,
    (COALESCE(store_agg.store_discount, 0) + COALESCE(web_agg.web_discount, 0)) / NULLIF((COALESCE(store_agg.store_customer_cnt, 0) + COALESCE(web_agg.web_customer_cnt, 0)), 0) AS avg_discount_per_customer,
    (COALESCE(store_agg.store_customer_cnt, 0) + COALESCE(web_agg.web_customer_cnt, 0)) AS total_customers,
    RANK() OVER (ORDER BY (COALESCE(store_agg.store_profit, 0) + COALESCE(web_agg.web_profit, 0)) DESC) AS profit_rank
FROM (
    SELECT t_hour, ca_country, c_birth_year FROM store_agg
    UNION
    SELECT t_hour, ca_country, c_birth_year FROM web_agg
) agg
LEFT JOIN store_agg ON agg.t_hour = store_agg.t_hour AND agg.ca_country = store_agg.ca_country AND agg.c_birth_year = store_agg.c_birth_year
LEFT JOIN web_agg ON agg.t_hour = web_agg.t_hour AND agg.ca_country = web_agg.ca_country AND agg.c_birth_year = web_agg.c_birth_year
ORDER BY profit_rank
LIMIT 10

WITH sales_filtered AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_net_profit,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        s.s_store_id,
        s.s_store_name,
        t.t_hour
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_store_name LIKE '%Market%'
      AND t.t_hour BETWEEN 9 AND 17
      AND regexp_like(c.c_email_address, '^.*@gmail\\.com$')
      AND regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) = (SELECT 'gmail.com')
)
SELECT
    s_store_id,
    s_store_name,
    substring(s_store_name, 1, 10) AS short_name,
    sum(ss_net_profit) AS total_net_profit,
    count(DISTINCT ss_customer_sk) AS distinct_customer_cnt,
    array_agg(DISTINCT concat(c_first_name, ' ', c_last_name)) FILTER (WHERE c_first_name IS NOT NULL) AS customer_names
FROM sales_filtered
GROUP BY s_store_id, s_store_name
ORDER BY total_net_profit DESC
LIMIT 100

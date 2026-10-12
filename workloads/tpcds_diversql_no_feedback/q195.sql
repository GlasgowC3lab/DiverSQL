WITH store_sales_agg AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    s.s_city,
    sum(ss.ss_net_profit) AS total_profit,
    avg(ss.ss_list_price) AS avg_list_price,
    avg(cast(regexp_extract(ca.ca_suite_number, '(\\d+)', 1) AS double)) AS avg_suite_num
  FROM
    store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE
    d.d_year = 2002
    AND s.s_city LIKE 'A%'
    AND ca.ca_suite_number LIKE 'Suite %'
    AND regexp_like(ca.ca_suite_number, 'Suite \\d+')
  GROUP BY
    s.s_store_sk,
    s.s_store_name,
    s.s_city
)
SELECT
  concat(s_store_name, ' - ', s_city) AS store_full_name,
  s_store_sk,
  total_profit,
  avg_list_price,
  avg_suite_num,
  substring(s_city, 1, 3) AS city_prefix,
  rank() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM store_sales_agg
ORDER BY profit_rank
LIMIT 100

WITH
  store_agg AS (
    SELECT
      'store' AS channel,
      d.d_year,
      ca.ca_state,
      SUM(ss.ss_net_paid) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY GROUPING SETS ((d.d_year, ca.ca_state), (d.d_year), ())
  ),
  web_agg AS (
    SELECT
      'web' AS channel,
      d.d_year,
      ca.ca_state,
      SUM(ws.ws_net_paid) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY GROUPING SETS ((d.d_year, ca.ca_state), (d.d_year), ())
  )
SELECT *
FROM store_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY channel, d_year NULLS LAST, ca_state
LIMIT 100

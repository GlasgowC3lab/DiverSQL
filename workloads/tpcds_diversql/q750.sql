WITH
  store_sales_sampled AS (
    SELECT
      ss.ss_addr_sk          AS address_sk,
      ss.ss_net_profit       AS profit,
      s.s_state              AS state,
      CAST(NULL AS varchar) AS page_type,
      'store'                AS source
    FROM tpcds.store_sales ss
    TABLESAMPLE BERNOULLI (10)
    JOIN tpcds.store s               ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.customer_address ca   ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE s.s_number_employees > 100               -- filter 1
      AND ca.ca_city = 'Green'                     -- filter 2
      AND cd.cd_purchase_estimate >= 4000          -- filter 3
      AND s.s_rec_start_date > DATE '2000-01-01'   -- filter 4
      AND ca.ca_state = 'CA'                       -- filter 5
  ),
  web_sales_sampled AS (
    SELECT
      ws.ws_bill_addr_sk     AS address_sk,
      ws.ws_net_profit       AS profit,
      ca.ca_state            AS state,
      wp.wp_type             AS page_type,
      'web'                  AS source
    FROM tpcds.web_sales ws
    TABLESAMPLE BERNOULLI (10)
    JOIN tpcds.web_page wp               ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.customer_address ca       ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE wp.wp_char_count > 3000               -- filter 1
      AND cd.cd_dep_college_count >= 3          -- filter 2
      AND ca.ca_county = 'Chelan County'       -- filter 3
      AND wp.wp_type = 'Content'                -- filter 4
      AND ca.ca_state = 'TX'                    -- filter 5
  ),
  intersect_addr AS (
    SELECT address_sk FROM store_sales_sampled
    INTERSECT
    SELECT address_sk FROM web_sales_sampled
  ),
  except_addr AS (
    SELECT address_sk FROM store_sales_sampled
    EXCEPT
    SELECT address_sk FROM web_sales_sampled
  ),
  combined_sales AS (
    SELECT * FROM store_sales_sampled
    UNION ALL
    SELECT * FROM web_sales_sampled
  )
SELECT
  state,
  page_type,
  SUM(profit) AS total_profit,
  COUNT(*)   AS txn_count,
  AVG(profit) AS avg_profit,
  MIN(profit) AS min_profit,
  MAX(profit) AS max_profit
FROM combined_sales
WHERE profit IS NOT NULL
  AND address_sk IN (SELECT address_sk FROM intersect_addr)
  AND address_sk NOT IN (SELECT address_sk FROM except_addr)
GROUP BY ROLLUP(state, page_type)
ORDER BY state, page_type
LIMIT 100

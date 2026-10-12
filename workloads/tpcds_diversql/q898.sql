WITH
  sales_agg AS (
    SELECT
      ca.ca_city AS ca_city,
      ca.ca_state AS ca_state,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
      SUM(DISTINCT ss.ss_quantity) AS distinct_quantity_sum
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ss.ss_ext_sales_price > 1000
      AND ss.ss_coupon_amt < 5000
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND ca.ca_location_type = 'single family'
      AND ss.ss_quantity BETWEEN 1 AND 10
      AND ss.ss_wholesale_cost > 10
    GROUP BY ROLLUP (ca.ca_city, ca.ca_state)
  ),
  returns_agg AS (
    SELECT
      ca.ca_city AS ca_city,
      wp.wp_type AS wp_type,
      COUNT(*) AS return_cnt,
      SUM(wr.wr_return_amt) AS total_return_amt,
      COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
    FROM web_returns wr
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_link_count >= 10
      AND wp.wp_max_ad_count <= 3
      AND wr.wr_return_amt > 0
      AND ca.ca_zip LIKE '9%'
      AND wr.wr_return_quantity > 0
      AND wp.wp_type <> 'unknown'
    GROUP BY ROLLUP (ca.ca_city, wp.wp_type)
  ),
  union_agg AS (
    SELECT
      ca_city AS city,
      ca_state AS state,
      total_sales,
      CAST(NULL AS decimal(7,2)) AS total_return_amt,
      distinct_tickets,
      distinct_quantity_sum,
      CAST(NULL AS bigint) AS return_cnt,
      CAST(NULL AS bigint) AS distinct_orders
    FROM sales_agg
    UNION DISTINCT
    SELECT
      ca_city AS city,
      CAST(NULL AS varchar) AS state,
      CAST(NULL AS decimal(7,2)) AS total_sales,
      total_return_amt,
      CAST(NULL AS bigint) AS distinct_tickets,
      CAST(NULL AS bigint) AS distinct_quantity_sum,
      return_cnt,
      distinct_orders
    FROM returns_agg
  ),
  city_excluded AS (
    SELECT ca_city AS city FROM returns_agg
    EXCEPT
    SELECT ca_city AS city FROM sales_agg
  )
SELECT
  ua.city,
  ua.state,
  SUM(ua.total_sales) AS agg_sales,
  SUM(ua.total_return_amt) AS agg_returns,
  COUNT(DISTINCT ua.distinct_tickets) AS cnt_distinct_tickets,
  SUM(ua.distinct_quantity_sum) AS sum_distinct_quantity,
  COUNT(DISTINCT ua.return_cnt) AS cnt_return_rows
FROM union_agg ua
WHERE ua.city NOT IN (SELECT city FROM city_excluded)
  AND (SELECT COUNT(*) FROM sales_agg sa WHERE sa.ca_city = ua.city) > 0
  AND EXISTS (
    SELECT 1 FROM returns_agg ra WHERE ra.ca_city = ua.city AND ra.return_cnt > 5
  )
GROUP BY ROLLUP (ua.city, ua.state)
ORDER BY agg_sales DESC NULLS LAST
LIMIT 100

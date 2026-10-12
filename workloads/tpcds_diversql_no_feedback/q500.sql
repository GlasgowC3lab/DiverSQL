WITH
  addr_from_sales AS (
    SELECT DISTINCT cs.cs_bill_addr_sk AS addr_sk
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '[0-9]{3}')
      AND ca.ca_street_name LIKE 'Spring%'
  ),
  addr_from_returns AS (
    SELECT DISTINCT sr.sr_addr_sk AS addr_sk
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_suite_number LIKE 'Suite %'
      AND regexp_extract(ca.ca_address_id, '\\d+', 0) IS NOT NULL
  ),
  common_addresses AS (
    SELECT addr_sk FROM addr_from_sales
    INTERSECT
    SELECT addr_sk FROM addr_from_returns
  ),
  sales_agg AS (
    SELECT cs.cs_bill_addr_sk AS addr_sk,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (
      SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2001
    )
    GROUP BY cs.cs_bill_addr_sk
  ),
  returns_agg AS (
    SELECT sr.sr_addr_sk AS addr_sk,
           SUM(sr.sr_return_amt) AS total_returns,
           COUNT(*) AS returns_cnt
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk IN (
      SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2001
    )
    GROUP BY sr.sr_addr_sk
  )
SELECT
  ca.ca_address_id,
  ca.ca_street_name,
  ca.ca_city || ', ' || ca.ca_state AS city_state,
  sa.total_sales,
  sa.sales_cnt,
  ra.total_returns,
  ra.returns_cnt
FROM common_addresses ca_addr
JOIN customer_address ca ON ca_addr.addr_sk = ca.ca_address_sk
LEFT JOIN sales_agg sa ON ca.ca_address_sk = sa.addr_sk
LEFT JOIN returns_agg ra ON ca.ca_address_sk = ra.addr_sk
ORDER BY sa.total_sales DESC NULLS LAST
LIMIT 100

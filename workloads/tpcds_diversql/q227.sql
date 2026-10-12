WITH store_data AS (
  SELECT
    c.c_customer_id,
    d.d_date,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(ss.ss_quantity) AS total_quantity,
    l.avg_price,
    'store' AS sales_channel
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  LEFT JOIN LATERAL (
    SELECT AVG(ss2.ss_sales_price) AS avg_price
    FROM store_sales ss2
    WHERE ss2.ss_customer_sk = ss.ss_customer_sk
      AND ss2.ss_sold_date_sk = ss.ss_sold_date_sk
  ) l ON TRUE
  WHERE d.d_year = 2001
    AND NOT EXISTS (
      SELECT 1 FROM catalog_returns cr
      WHERE cr.cr_refunded_customer_sk = ss.ss_customer_sk
        AND cr.cr_returned_date_sk = ss.ss_sold_date_sk
    )
    AND NOT EXISTS (
      SELECT 1 FROM web_returns wr
      WHERE wr.wr_refunded_customer_sk = ss.ss_customer_sk
        AND wr.wr_returned_date_sk = ss.ss_sold_date_sk
    )
  GROUP BY c.c_customer_id, d.d_date, l.avg_price
),
catalog_data AS (
  SELECT
    c.c_customer_id,
    d.d_date,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cs.cs_quantity) AS total_quantity,
    l.avg_price,
    'catalog' AS sales_channel
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN LATERAL (
    SELECT AVG(cs2.cs_list_price) AS avg_price
    FROM catalog_sales cs2
    WHERE cs2.cs_bill_customer_sk = cs.cs_bill_customer_sk
      AND cs2.cs_sold_date_sk = cs.cs_sold_date_sk
  ) l ON TRUE
  WHERE d.d_year = 2001
    AND NOT EXISTS (
      SELECT 1 FROM catalog_returns cr
      WHERE cr.cr_refunded_customer_sk = cs.cs_bill_customer_sk
        AND cr.cr_returned_date_sk = cs.cs_sold_date_sk
    )
    AND NOT EXISTS (
      SELECT 1 FROM web_returns wr
      WHERE wr.wr_refunded_customer_sk = cs.cs_bill_customer_sk
        AND wr.wr_returned_date_sk = cs.cs_sold_date_sk
    )
  GROUP BY c.c_customer_id, d.d_date, l.avg_price
)
SELECT *
FROM store_data
UNION ALL
SELECT *
FROM catalog_data
ORDER BY total_sales DESC
LIMIT 100

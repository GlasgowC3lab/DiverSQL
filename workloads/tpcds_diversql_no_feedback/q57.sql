WITH
  web_agg AS (
    SELECT
      ws.ws_item_sk AS item_sk,
      d.d_date_sk AS date_sk,
      SUM(ws.ws_quantity) AS total_quantity,
      SUM(ws.ws_net_paid) AS total_net_paid,
      SUM(ws.ws_ext_discount_amt) AS total_discount,
      CAST(NULL AS BIGINT) AS total_return_qty,
      CAST(NULL AS DECIMAL(7,2)) AS total_return_amount
    FROM web_sales ws
    RIGHT JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2000
      AND i.i_brand_id IN (1002001, 2002002)
      AND ca.ca_county = 'Maricopa County'
      AND c.c_birth_country = 'TOGO'
    GROUP BY ws.ws_item_sk, d.d_date_sk
  ),
  returns_agg AS (
    SELECT
      cr.cr_item_sk AS item_sk,
      d.d_date_sk AS date_sk,
      CAST(NULL AS BIGINT) AS total_quantity,
      CAST(NULL AS DECIMAL(7,2)) AS total_net_paid,
      CAST(NULL AS DECIMAL(7,2)) AS total_discount,
      SUM(cr.cr_return_quantity) AS total_return_qty,
      SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2000
      AND i.i_brand_id IN (1002001, 2002002)
      AND ca.ca_county = 'Maricopa County'
      AND c.c_birth_country = 'TOGO'
    GROUP BY cr.cr_item_sk, d.d_date_sk
  ),
  union_all AS (
    SELECT * FROM web_agg
    UNION DISTINCT
    SELECT * FROM returns_agg
  ),
  full_u AS (
    SELECT u.*, d.d_year
    FROM union_all u
    FULL OUTER JOIN date_dim d
      ON u.date_sk = d.d_date_sk
  )
SELECT
  i.i_brand,
  i.i_category,
  SUM(COALESCE(fu.total_quantity, 0)) AS sum_quantity,
  SUM(COALESCE(fu.total_net_paid, 0)) AS sum_net_paid,
  SUM(COALESCE(fu.total_return_qty, 0)) AS sum_return_quantity,
  SUM(COALESCE(fu.total_return_amount, 0)) AS sum_return_amount,
  AVG(fu.total_discount) AS avg_discount
FROM full_u fu
RIGHT OUTER JOIN item i
  ON fu.item_sk = i.i_item_sk
GROUP BY i.i_brand, i.i_category
HAVING SUM(COALESCE(fu.total_net_paid, 0)) > 10000
ORDER BY sum_net_paid DESC
LIMIT 100

WITH
  refunded_returns AS (
    SELECT
      wr.wr_order_number               AS order_number,
      'refunded'                       AS address_type,
      ca.ca_city                       AS city,
      ca.ca_zip                        AS zip,
      r.r_reason_desc                  AS reason_desc,
      wr.wr_returned_date_sk           AS return_date_sk,
      t.amount_type                    AS amount_type,
      t.amount_value                   AS amount_value
    FROM
      web_returns wr
      INNER JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
      INNER JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
      CROSS JOIN UNNEST(
        map(
          ARRAY['return_amt', 'return_tax'],
          ARRAY[wr.wr_return_amt, wr.wr_return_tax]
        )
      ) AS t(amount_type, amount_value)
    WHERE
      ca.ca_county = 'Washington County'
      AND r.r_reason_sk = 5
  ),
  returning_returns AS (
    SELECT
      wr.wr_order_number               AS order_number,
      'returning'                      AS address_type,
      ca.ca_city                       AS city,
      ca.ca_zip                        AS zip,
      r.r_reason_desc                  AS reason_desc,
      wr.wr_returned_date_sk           AS return_date_sk,
      t.amount_type                    AS amount_type,
      t.amount_value                   AS amount_value
    FROM
      web_returns wr
      INNER JOIN customer_address ca
        ON wr.wr_returning_addr_sk = ca.ca_address_sk
      INNER JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
      CROSS JOIN UNNEST(
        map(
          ARRAY['return_amt', 'return_tax'],
          ARRAY[wr.wr_return_amt, wr.wr_return_tax]
        )
      ) AS t(amount_type, amount_value)
    WHERE
      ca.ca_zip = '90419'
      AND wr.wr_return_tax > 20
  ),
  combined AS (
    SELECT * FROM refunded_returns
    UNION ALL
    SELECT * FROM returning_returns
  )
SELECT
  ROW_NUMBER() OVER (ORDER BY return_date_sk, order_number) AS row_num,
  order_number,
  address_type,
  city,
  zip,
  reason_desc,
  return_date_sk,
  amount_type,
  amount_value
FROM
  combined
ORDER BY
  row_num
LIMIT 100

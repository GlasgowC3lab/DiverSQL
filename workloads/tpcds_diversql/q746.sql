WITH filtered_catalog AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_returned_time_sk,
        cr.cr_reason_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_refunded_cdemo_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 100
      AND cr.cr_return_quantity BETWEEN 1 AND 5
      AND cr.cr_returned_time_sk IN (
          SELECT t_time_sk FROM time_dim WHERE t_hour BETWEEN 9 AND 17
      )
),
filtered_web AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_returned_time_sk,
        wr.wr_reason_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_refunded_cdemo_sk
    FROM web_returns wr
    WHERE wr.wr_return_amt > 50
      AND wr.wr_return_quantity BETWEEN 1 AND 5
      AND wr.wr_returned_time_sk IN (
          SELECT t_time_sk FROM time_dim WHERE t_hour BETWEEN 9 AND 17
      )
),
small_reason AS (
    SELECT r_reason_sk
    FROM reason
    WHERE r_reason_desc LIKE '%defective%'
    LIMIT 5
),
hour_set AS (
    SELECT 9 AS cross_hour UNION ALL SELECT 10 UNION ALL SELECT 11
)
SELECT
    r.r_reason_desc,
    td.t_hour,
    ca.ca_state,
    cd.cd_credit_rating,
    h.cross_hour,
    SUM(fc.cr_return_amount) AS total_catalog_return_amount,
    SUM(fw.wr_return_amt) AS total_web_return_amount,
    COUNT(DISTINCT fc.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT fw.wr_order_number) AS web_orders,
    ROW_NUMBER() OVER (
        PARTITION BY r.r_reason_desc
        ORDER BY SUM(fc.cr_return_amount) + SUM(fw.wr_return_amt) DESC
    ) AS reason_rank
FROM filtered_catalog fc
JOIN filtered_web fw
    ON fc.cr_order_number = fw.wr_order_number
JOIN reason r
    ON fc.cr_reason_sk = r.r_reason_sk
JOIN time_dim td
    ON fc.cr_returned_time_sk = td.t_time_sk
JOIN customer_address ca
    ON fc.cr_refunded_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON fc.cr_refunded_cdemo_sk = cd.cd_demo_sk
CROSS JOIN small_reason sr
CROSS JOIN hour_set h
WHERE ca.ca_state = 'CA'
  AND cd.cd_credit_rating = 'Good'
  AND r.r_reason_desc LIKE '%defective%'
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = fc.cr_order_number
          AND wr2.wr_return_amt > 0
    )
GROUP BY r.r_reason_desc, td.t_hour, ca.ca_state, cd.cd_credit_rating, h.cross_hour
ORDER BY total_catalog_return_amount DESC
LIMIT 100

WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_call_center_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_returning_addr_sk,
        cr.cr_ship_mode_sk,
        cr.cr_reason_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
      AND cr.cr_return_amount > 100
      AND cr.cr_return_quantity >= 2
)
SELECT
    cc.cc_name,
    ca_ref.ca_state AS refunded_state,
    ca_ret.ca_city AS returning_city,
    r.r_reason_desc,
    sm.sm_type,
    COUNT(DISTINCT filtered_returns.cr_order_number) AS orders_cnt,
    SUM(filtered_returns.cr_return_amount) AS total_return_amount,
    AVG(filtered_returns.cr_return_quantity) AS avg_quantity,
    MIN(filtered_returns.cr_net_loss) AS min_net_loss,
    MAX(filtered_returns.cr_net_loss) AS max_net_loss,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_reason_sk = filtered_returns.cr_reason_sk
          AND cr2.cr_call_center_sk = filtered_returns.cr_call_center_sk
    ) AS reason_center_total_return_amount
FROM filtered_returns
JOIN call_center cc
  ON filtered_returns.cr_call_center_sk = cc.cc_call_center_sk
JOIN customer_address ca_ref
  ON filtered_returns.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret
  ON filtered_returns.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN reason r
  ON filtered_returns.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
  ON filtered_returns.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE ca_ref.ca_zip = '90419'
  AND ca_ret.ca_location_type = 'apartment'
  AND r.r_reason_desc LIKE '%damaged%'
GROUP BY
    cc.cc_name,
    ca_ref.ca_state,
    ca_ret.ca_city,
    r.r_reason_desc,
    sm.sm_type,
    filtered_returns.cr_reason_sk,
    filtered_returns.cr_call_center_sk
ORDER BY total_return_amount DESC
LIMIT 100

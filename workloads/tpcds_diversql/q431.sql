WITH returns_filtered AS (
    SELECT cr.cr_returned_date_sk,
           cr.cr_returned_time_sk,
           cr.cr_warehouse_sk,
           cr.cr_reason_sk,
           cr.cr_return_amount
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE r.r_reason_desc LIKE '%did not%'
      AND w.w_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_returned_date_sk = cr.cr_returned_date_sk
            AND cr2.cr_return_amount > 100
      )
),
sales_filtered AS (
    SELECT ws.ws_sold_date_sk,
           ws.ws_sold_time_sk,
           ws.ws_warehouse_sk,
           ws.ws_promo_sk,
           ws.ws_ext_sales_price
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE p.p_discount_active = 'Y'
      AND w.w_state = 'CA'
),
intersect_keys AS (
    SELECT cr_returned_date_sk AS date_key
    FROM returns_filtered
    INTERSECT
    SELECT ws_sold_date_sk AS date_key
    FROM sales_filtered
),
except_keys AS (
    SELECT cr_returned_date_sk AS date_key
    FROM returns_filtered
    EXCEPT
    SELECT ws_sold_date_sk AS date_key
    FROM sales_filtered
)
SELECT
    final.date_key,
    final.source,
    ROW_NUMBER() OVER (ORDER BY final.date_key) AS rn
FROM (
    SELECT date_key, 'both' AS source FROM intersect_keys
    UNION ALL
    SELECT date_key, 'returns_only' AS source FROM except_keys
) final
ORDER BY final.date_key
LIMIT 100

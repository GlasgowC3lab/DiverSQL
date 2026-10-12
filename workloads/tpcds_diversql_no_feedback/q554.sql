WITH
  returns_a AS (
    SELECT
      r.r_reason_desc AS reason_desc,
      i.i_item_sk AS item_sk,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_warehouse_sk = 7
      AND i.i_size = 'large'
      AND cr.cr_return_amount > 0
    GROUP BY r.r_reason_desc, i.i_item_sk
  ),
  returns_b AS (
    SELECT
      r.r_reason_desc AS reason_desc,
      i.i_item_sk AS item_sk,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_warehouse_sk = 11
      AND i.i_size = 'small'
      AND cr.cr_return_amount > 0
    GROUP BY r.r_reason_desc, i.i_item_sk
  ),
  union_returns AS (
    SELECT * FROM returns_a
    UNION ALL
    SELECT * FROM returns_b
  )
SELECT
  u.reason_desc,
  u.item_sk,
  u.total_return_amount,
  u.total_return_quantity
FROM union_returns u
WHERE EXISTS (
  SELECT 1
  FROM promotion p
  JOIN item i2 ON p.p_item_sk = i2.i_item_sk
  WHERE i2.i_item_sk = u.item_sk
    AND p.p_discount_active = 'Y'
)
ORDER BY u.total_return_amount DESC
LIMIT 100

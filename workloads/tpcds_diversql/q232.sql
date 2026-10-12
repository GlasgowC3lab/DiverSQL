WITH item_not_in_web AS (
  SELECT cr_item_sk
  FROM catalog_returns
  EXCEPT
  SELECT wr_item_sk
  FROM web_returns
)
SELECT
  d.d_year,
  i.i_category,
  r.r_reason_desc,
  SUM(cr.cr_return_amount) AS total_return_amount,
  COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
  CASE
    WHEN SUM(cr.cr_return_quantity) > 100 THEN 'High Volume'
    ELSE 'Normal Volume'
  END AS volume_category,
  (
    SELECT SUM(inv_quantity_on_hand)
    FROM inventory inv
    WHERE inv.inv_item_sk = cr.cr_item_sk
      AND inv.inv_date_sk = cr.cr_returned_date_sk
  ) AS inventory_on_return_date,
  (
    SELECT COUNT(*)
    FROM web_page wp2
    WHERE wp2.wp_customer_sk = cr.cr_returning_customer_sk
      AND wp2.wp_access_date_sk = d.d_date_sk
  ) AS pages_accessed_by_customer
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN customer c_ref
  ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer_address ca_ref
  ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer c_ret
  ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
JOIN customer_address ca_ret
  ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN web_returns wr
  ON cr.cr_item_sk = wr.wr_item_sk
  AND cr.cr_returned_date_sk = wr.wr_returned_date_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws
  ON wp.wp_creation_date_sk = ws.web_open_date_sk
JOIN inventory inv
  ON inv.inv_item_sk = cr.cr_item_sk
  AND inv.inv_date_sk = cr.cr_returned_date_sk
WHERE cr.cr_item_sk IN (SELECT cr_item_sk FROM item_not_in_web)
GROUP BY
  d.d_year,
  i.i_category,
  r.r_reason_desc,
  d.d_date_sk,
  cr.cr_returning_customer_sk,
  cr.cr_item_sk,
  cr.cr_returned_date_sk
ORDER BY total_return_amount DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY

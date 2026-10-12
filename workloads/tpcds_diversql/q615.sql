WITH
  cs_cc AS (
    SELECT
      cc.cc_call_center_id,
      cc.cc_name,
      COALESCE(SUM(cs.cs_net_profit), 0) AS total_profit,
      COUNT(cs.cs_order_number) AS order_cnt,
      CASE
        WHEN COALESCE(SUM(cs.cs_net_profit), 0) > 1000000 THEN 'High'
        WHEN COALESCE(SUM(cs.cs_net_profit), 0) > 100000  THEN 'Medium'
        ELSE 'Low'
      END AS profit_category
    FROM catalog_sales cs
    RIGHT OUTER JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY cc.cc_call_center_id, cc.cc_name
  ),
  inv_cr_full AS (
    SELECT
      i.i_item_id,
      i.i_product_name,
      inv.inv_quantity_on_hand,
      cr.cr_return_amount,
      CASE
        WHEN inv.inv_quantity_on_hand IS NULL THEN 'NoInv'
        WHEN cr.cr_return_amount IS NULL THEN 'NoReturn'
        ELSE 'Both'
      END AS inv_return_status,
      regexp_extract(i.i_product_name, '([A-Z]{2}[0-9]{3})', 1) AS product_code
    FROM inventory inv
    FULL OUTER JOIN catalog_returns cr
      ON inv.inv_item_sk = cr.cr_item_sk
    LEFT JOIN item i
      ON (inv.inv_item_sk = i.i_item_sk OR cr.cr_item_sk = i.i_item_sk)
    WHERE i.i_product_name IS NOT NULL
      AND regexp_like(i.i_product_name, '^[A-Z]{2}[0-9]{3}')
      AND i.i_brand LIKE 'Brand%'
  )
SELECT
  cs.cc_call_center_id,
  cs.cc_name,
  substring(cs.cc_name, 1, 5) AS cc_name_prefix,
  cs.total_profit,
  cs.order_cnt,
  cs.profit_category,
  concat(cs.cc_name, ' - ', cs.profit_category) AS name_category
FROM cs_cc cs
WHERE EXISTS (
  SELECT 1
  FROM inv_cr_full ic
  WHERE ic.product_code IS NOT NULL
    AND ic.inv_return_status = 'Both'
)
ORDER BY cs.total_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

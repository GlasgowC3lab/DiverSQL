WITH filtered_items AS (
    SELECT i_item_sk,
           i_item_desc,
           i_color,
           i_brand
    FROM tpcds.item
    WHERE regexp_like(i_item_desc, '.*[0-9]{2,}.*')
      AND i_color LIKE 'B%'
)
SELECT
    cc.cc_call_center_id,
    concat(cc.cc_city, ', ', cc.cc_state) AS call_center_location,
    substring(cc.cc_name, 1, 5) AS cc_name_prefix,
    COUNT(DISTINCT cr.cr_order_number) AS returned_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty
FROM tpcds.catalog_returns cr
JOIN tpcds.call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN filtered_items fi
  ON cr.cr_item_sk = fi.i_item_sk
JOIN tpcds.date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND regexp_like(cc.cc_name, '^.*Center$')
  AND cc.cc_city LIKE 'A%'
GROUP BY
    cc.cc_call_center_id,
    cc.cc_city,
    cc.cc_state,
    cc.cc_name
ORDER BY total_net_loss DESC
LIMIT 100

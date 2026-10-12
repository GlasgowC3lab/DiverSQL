WITH base AS (
  SELECT
    cr.cr_returned_time_sk,
    cr.cr_item_sk,
    cr.cr_catalog_page_sk,
    cr.cr_warehouse_sk,
    cr.cr_refunded_addr_sk,
    cr.cr_return_quantity,
    cr.cr_net_loss,
    t.t_sub_shift,
    i.i_category,
    cp.cp_department,
    w.w_warehouse_name,
    ca.ca_state,
    (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_item_sk = cr.cr_item_sk) AS store_ret_cnt
  FROM catalog_returns cr
  JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
),
store_part AS (
  SELECT
    sr.sr_return_time_sk,
    sr.sr_item_sk,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    t2.t_sub_shift AS store_sub_shift,
    i2.i_category AS store_category,
    ca2.ca_state AS store_state,
    (SELECT COUNT(*) FROM store_returns sr3 WHERE sr3.sr_item_sk = sr.sr_item_sk) AS store_ret_cnt
  FROM store_returns sr
  JOIN time_dim t2
    ON sr.sr_return_time_sk = t2.t_time_sk
  JOIN item i2
    ON sr.sr_item_sk = i2.i_item_sk
  JOIN customer_address ca2
    ON sr.sr_addr_sk = ca2.ca_address_sk
)
SELECT
  agg.w_warehouse_name,
  agg.t_sub_shift,
  agg.cp_department,
  SUM(agg.net_loss) AS total_net_loss,
  SUM(agg.return_quantity) AS total_return_qty,
  COUNT(DISTINCT agg.item_category) AS distinct_categories,
  MAX(agg.store_ret_cnt) AS max_store_ret_cnt
FROM (
  SELECT
    b.w_warehouse_name,
    b.t_sub_shift,
    b.cp_department,
    b.cr_net_loss AS net_loss,
    b.cr_return_quantity AS return_quantity,
    b.i_category AS item_category,
    b.store_ret_cnt
  FROM base b
  UNION DISTINCT
  SELECT
    CAST(NULL AS varchar) AS w_warehouse_name,
    sp.store_sub_shift AS t_sub_shift,
    cp.cp_department,
    sp.sr_return_amt * 0.0 AS net_loss,
    sp.sr_return_quantity AS return_quantity,
    sp.store_category AS item_category,
    sp.store_ret_cnt
  FROM store_part sp
  JOIN catalog_page cp
    ON 1 = 1
) AS agg
LEFT JOIN LATERAL (
  SELECT val
  FROM UNNEST(ARRAY[agg.return_quantity, agg.store_ret_cnt]) AS t(val)
) AS l(val) ON true
GROUP BY agg.w_warehouse_name, agg.t_sub_shift, agg.cp_department
ORDER BY total_net_loss DESC
LIMIT 100

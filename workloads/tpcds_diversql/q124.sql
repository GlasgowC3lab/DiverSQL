SELECT
  store.s_city,
  store.s_state,
  SUM(store_sales.ss_net_paid_inc_tax) AS total_net_paid_inc_tax
FROM
  store_sales
JOIN
  store
  ON store_sales.ss_store_sk = store.s_store_sk
WHERE
  store_sales.ss_net_paid_inc_tax > 1000
  AND store_sales.ss_ext_discount_amt > 100
  AND store.s_zip = '54536'
GROUP BY
  store.s_city,
  store.s_state

WITH
  store_data AS (
    SELECT
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk,
      sr.sr_store_sk,
      sr.sr_net_loss,
      sr.sr_return_quantity,
      d.d_year,
      t.t_hour,
      s.s_state,
      s.s_store_name
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 1903
      AND s.s_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
      AND sr.sr_return_quantity > 10
      AND sr.sr_net_loss > 0
  ),
  catalog_data AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_warehouse_sk,
      cr.cr_net_loss,
      cr.cr_return_quantity,
      d.d_year,
      t.t_hour,
      w.w_city
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 1903
      AND w.w_city = 'Seattle'
      AND t.t_hour BETWEEN 9 AND 17
      AND cr.cr_return_quantity > 5
      AND cr.cr_net_loss > 0
  ),
  web_data AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_returned_time_sk,
      wr.wr_return_quantity,
      wr.wr_net_loss,
      d.d_year,
      t.t_hour,
      wr.wr_reason_sk
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE d.d_year = 1903
      AND t.t_hour BETWEEN 9 AND 17
      AND wr.wr_return_quantity > 2
      AND wr.wr_net_loss > 0
      AND wr.wr_reason_sk IS NOT NULL
  ),
  inventory_data AS (
    SELECT
      inv.inv_date_sk,
      inv.inv_warehouse_sk,
      inv.inv_quantity_on_hand,
      d.d_year,
      w.w_city
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    RIGHT OUTER JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE (d.d_year = 1903 OR d.d_year IS NULL)
      AND w.w_city = 'Seattle'
  ),
  combined AS (
    SELECT
      COALESCE(s.sr_returned_date_sk, c.cr_returned_date_sk) AS date_sk,
      COALESCE(s.d_year, c.d_year) AS year,
      COALESCE(s.s_state, 'UNKNOWN') AS state,
      COALESCE(c.w_city, 'UNKNOWN') AS city,
      COALESCE(s.sr_net_loss, 0) + COALESCE(c.cr_net_loss, 0) AS total_net_loss,
      COALESCE(s.sr_return_quantity, 0) + COALESCE(c.cr_return_quantity, 0) AS total_return_qty
    FROM store_data s
    FULL OUTER JOIN catalog_data c
      ON s.sr_returned_date_sk = c.cr_returned_date_sk
  )
SELECT
  cmb.year,
  cmb.state,
  cmb.city,
  SUM(cmb.total_net_loss) AS sum_net_loss,
  SUM(cmb.total_return_qty) AS sum_return_qty,
  COUNT(*) AS cnt_rows,
  MIN(cmb.total_net_loss) AS min_net_loss,
  MAX(cmb.total_net_loss) AS max_net_loss
FROM combined cmb
LEFT JOIN web_data wd ON cmb.date_sk = wd.wr_returned_date_sk
LEFT JOIN inventory_data id ON cmb.city = id.w_city AND cmb.year = id.d_year
WHERE cmb.year = 1903
  AND cmb.state = 'CA'
  AND cmb.city = 'Seattle'
GROUP BY cmb.year, cmb.state, cmb.city
HAVING SUM(cmb.total_net_loss) > 1000
ORDER BY sum_net_loss DESC
LIMIT 100

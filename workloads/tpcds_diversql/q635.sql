/* Goal: Identify high‑loss customers (total loss ≥ 1000) for the year 2020 who did not have returns both in store and catalog channels, combine this list with a cross‑joined set of the top 3 ship modes and yearly loss totals, rank all rows by the loss metric, and include an average yearly loss as a scalar reference value. */
WITH
  /* Aggregate store returns for 2020 */
  store_returns_agg AS (
    SELECT
      sr.sr_customer_sk AS customer_sk,
      d.d_year,
      SUM(sr.sr_net_loss) AS net_loss
    FROM tpcds.store_returns sr
    JOIN tpcds.date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY sr.sr_customer_sk, d.d_year
  ),
  /* Aggregate catalog returns for 2020 */
  catalog_returns_agg AS (
    SELECT
      cr.cr_refunded_customer_sk AS customer_sk,
      d.d_year,
      SUM(cr.cr_net_loss) AS net_loss
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY cr.cr_refunded_customer_sk, d.d_year
  ),
  /* Aggregate web returns for 2020 */
  web_returns_agg AS (
    SELECT
      wr.wr_refunded_customer_sk AS customer_sk,
      d.d_year,
      SUM(wr.wr_net_loss) AS net_loss
    FROM tpcds.web_returns wr
    JOIN tpcds.date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY wr.wr_refunded_customer_sk, d.d_year
  ),
  /* Union all channel losses */
  all_returns AS (
    SELECT customer_sk, d_year, net_loss FROM store_returns_agg
    UNION ALL
    SELECT customer_sk, d_year, net_loss FROM catalog_returns_agg
    UNION ALL
    SELECT customer_sk, d_year, net_loss FROM web_returns_agg
  ),
  /* Customers whose total loss in 2020 is at least 1000 */
  high_loss_customers AS (
    SELECT customer_sk
    FROM all_returns
    GROUP BY customer_sk
    HAVING SUM(net_loss) >= 1000
  ),
  /* Customers who returned items via store in 2020 */
  store_customers AS (
    SELECT DISTINCT sr.sr_customer_sk AS customer_sk
    FROM tpcds.store_returns sr
    JOIN tpcds.date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
  ),
  /* Customers who returned items via catalog in 2020 */
  catalog_customers AS (
    SELECT DISTINCT cr.cr_refunded_customer_sk AS customer_sk
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
  ),
  /* Customers who appear in BOTH store and catalog return sets */
  common_store_catalog AS (
    SELECT customer_sk FROM store_customers
    INTERSECT
    SELECT customer_sk FROM catalog_customers
  ),
  /* Customers that are high‑loss but NOT common to store & catalog */
  filtered_customers AS (
    SELECT hlc.customer_sk
    FROM high_loss_customers hlc
    EXCEPT
    SELECT csc.customer_sk FROM common_store_catalog csc
  ),
  /* Total loss per customer (used for ranking) */
  customer_total_loss AS (
    SELECT
      ar.customer_sk,
      SUM(ar.net_loss) AS total_loss
    FROM all_returns ar
    GROUP BY ar.customer_sk
  ),
  /* Top 3 ship modes (small dimension) */
  top_ship_modes AS (
    SELECT sm_ship_mode_id, sm_type
    FROM tpcds.ship_mode
    ORDER BY sm_ship_mode_id
    LIMIT 3
  ),
  /* Yearly loss totals (used for cross join) */
  yearly_loss AS (
    SELECT d_year, SUM(net_loss) AS year_total_loss
    FROM all_returns
    GROUP BY d_year
  ),
  /* Cartesian product of the small ship‑mode set with yearly loss */
  cross_join_set AS (
    SELECT
      ts.sm_ship_mode_id,
      yl.d_year,
      yl.year_total_loss
    FROM top_ship_modes ts
    CROSS JOIN yearly_loss yl
  ),
  /* Scalar sub‑query: average yearly loss across all years */
  avg_yearly_loss AS (
    SELECT AVG(year_total_loss) AS avg_loss FROM yearly_loss
  )

SELECT
  'customer' AS entity_type,
  CAST(fc.customer_sk AS VARCHAR) AS entity_id,
  ctl.total_loss AS metric,
  RANK() OVER (ORDER BY ctl.total_loss DESC) AS loss_rank,
  (SELECT avg_loss FROM avg_yearly_loss) AS avg_yearly_loss_ref
FROM filtered_customers fc
JOIN customer_total_loss ctl ON fc.customer_sk = ctl.customer_sk

UNION ALL

SELECT
  'ship_mode_year' AS entity_type,
  CONCAT(cj.sm_ship_mode_id, '-', CAST(cj.d_year AS VARCHAR)) AS entity_id,
  cj.year_total_loss AS metric,
  RANK() OVER (ORDER BY cj.year_total_loss DESC) AS loss_rank,
  (SELECT avg_loss FROM avg_yearly_loss) AS avg_yearly_loss_ref
FROM cross_join_set cj

ORDER BY metric DESC

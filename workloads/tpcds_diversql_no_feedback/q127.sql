WITH
  sales_sub AS (
    SELECT
      sm.sm_ship_mode_id AS ship_mode_id,
      sm.sm_type AS ship_mode_type,
      'sales' AS metric_type,
      cs.cs_ext_sales_price AS amount,
      cs.cs_quantity AS qty,
      ARRAY[CAST(cs.cs_quantity AS varchar), CAST(cs.cs_sales_price AS varchar)] AS metrics_array
    FROM catalog_sales cs
    RIGHT JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cp.cp_catalog_page_number IN (1, 12)
      AND cd.cd_gender = 'M'
  ),
  sales_unnest AS (
    SELECT
      ship_mode_id,
      ship_mode_type,
      metric_type,
      amount,
      qty,
      metric_value,
      metric_position
    FROM sales_sub
    CROSS JOIN UNNEST(metrics_array) WITH ORDINALITY AS t(metric_value, metric_position)
  ),
  sales_agg AS (
    SELECT
      ship_mode_id,
      ship_mode_type,
      metric_type,
      SUM(amount) AS total_amount,
      SUM(qty) AS total_quantity,
      MAX(metric_value) AS any_metric_value,
      MAX(metric_position) AS any_metric_position
    FROM sales_unnest
    GROUP BY ship_mode_id, ship_mode_type, metric_type
  ),
  sales_final AS (
    SELECT
      ship_mode_id,
      ship_mode_type,
      metric_type,
      total_amount,
      total_quantity,
      any_metric_value AS metric_value,
      any_metric_position AS metric_position,
      RANK() OVER (PARTITION BY ship_mode_id ORDER BY total_amount DESC) AS rank
    FROM sales_agg
  ),

  returns_sub AS (
    SELECT
      sm.sm_ship_mode_id AS ship_mode_id,
      sm.sm_type AS ship_mode_type,
      'returns' AS metric_type,
      cr.cr_return_amount AS amount,
      cr.cr_return_quantity AS qty,
      ARRAY[CAST(cr.cr_return_quantity AS varchar), CAST(cr.cr_return_amount AS varchar)] AS metrics_array
    FROM catalog_returns cr
    RIGHT JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_catalog_number BETWEEN 1 AND 5
      AND cr.cr_return_amount > 100
  ),
  returns_unnest AS (
    SELECT
      ship_mode_id,
      ship_mode_type,
      metric_type,
      amount,
      qty,
      metric_value,
      metric_position
    FROM returns_sub
    CROSS JOIN UNNEST(metrics_array) WITH ORDINALITY AS t(metric_value, metric_position)
  ),
  returns_agg AS (
    SELECT
      ship_mode_id,
      ship_mode_type,
      metric_type,
      SUM(amount) AS total_amount,
      SUM(qty) AS total_quantity,
      MAX(metric_value) AS any_metric_value,
      MAX(metric_position) AS any_metric_position
    FROM returns_unnest
    GROUP BY ship_mode_id, ship_mode_type, metric_type
  ),
  returns_final AS (
    SELECT
      ship_mode_id,
      ship_mode_type,
      metric_type,
      total_amount,
      total_quantity,
      any_metric_value AS metric_value,
      any_metric_position AS metric_position,
      RANK() OVER (PARTITION BY ship_mode_id ORDER BY total_amount DESC) AS rank
    FROM returns_agg
  )
SELECT *
FROM sales_final
UNION ALL
SELECT *
FROM returns_final
ORDER BY ship_mode_id, rank
LIMIT 100

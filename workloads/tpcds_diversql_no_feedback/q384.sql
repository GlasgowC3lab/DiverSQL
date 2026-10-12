WITH overall_max_sqft AS (
    SELECT max(w_warehouse_sq_ft) AS max_sqft
    FROM warehouse
)
SELECT *
FROM (
    SELECT
        d.d_year AS year,
        'store' AS return_type,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
        om.max_sqft AS overall_max_sqft
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    CROSS JOIN overall_max_sqft om
    WHERE cd.cd_purchase_estimate > 5000
      AND cd.cd_dep_employed_count >= 2
      AND d.d_year BETWEEN 2000 AND 2005
    GROUP BY d.d_year, om.max_sqft
) 
UNION ALL
SELECT
    d.d_year AS year,
    'catalog' AS return_type,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_customers,
    om.max_sqft AS overall_max_sqft
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
CROSS JOIN overall_max_sqft om
WHERE w.w_warehouse_sq_ft > 5000
  AND cd.cd_purchase_estimate > 5000
  AND cd.cd_dep_employed_count >= 2
  AND d.d_year BETWEEN 2000 AND 2005
  AND EXISTS (
      SELECT 1
      FROM call_center cc
      WHERE cc.cc_call_center_sk = cr.cr_call_center_sk
        AND cc.cc_gmt_offset > -5
  )
GROUP BY d.d_year, om.max_sqft
ORDER BY year, return_type
LIMIT 100

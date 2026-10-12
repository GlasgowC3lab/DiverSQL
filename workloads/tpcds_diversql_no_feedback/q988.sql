WITH base AS (
   SELECT 
       cr.cr_order_number AS order_number,
       cr.cr_return_amount AS return_amount,
       cr.cr_return_tax AS return_tax,
       ws.web_market_manager AS manager,
       ws.web_name AS site_name,
       ws.web_zip,
       d_ret.d_year
   FROM catalog_returns cr
   JOIN date_dim d_ret
       ON cr.cr_returned_date_sk = d_ret.d_date_sk
   JOIN web_site ws
       ON ws.web_open_date_sk = d_ret.d_date_sk
   WHERE ws.web_market_manager LIKE '%James%'
     AND regexp_like(ws.web_name, 'Store')
     AND ws.web_zip LIKE '9%'
),

exclude_set AS (
   SELECT cr.cr_order_number AS order_number
   FROM catalog_returns cr
   JOIN date_dim d_ret
       ON cr.cr_returned_date_sk = d_ret.d_date_sk
   WHERE cr.cr_return_tax > 100
),

keep_set AS (
   SELECT order_number FROM (
       SELECT order_number FROM base
   )
   EXCEPT
   SELECT order_number FROM exclude_set
)

SELECT 
    manager,
    COUNT(DISTINCT order_number) AS distinct_orders,
    SUM(return_amount) AS total_return_amount,
    AVG(return_tax) AS avg_return_tax,
    CONCAT('Mgr: ', manager) AS manager_label,
    SUBSTRING(site_name, 1, 5) AS name_prefix,
    REGEXP_EXTRACT(web_zip, '([0-9]{5})', 1) AS zip_code
FROM base
WHERE order_number IN (SELECT order_number FROM keep_set)
GROUP BY manager, site_name, web_zip
ORDER BY total_return_amount DESC
LIMIT 100

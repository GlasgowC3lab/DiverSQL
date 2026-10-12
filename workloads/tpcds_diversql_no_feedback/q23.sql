WITH gift_returns AS (
   SELECT cr.cr_order_number
   FROM catalog_returns cr
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE regexp_like(r.r_reason_desc, '(?i)gift')
),
holiday_page_returns AS (
   SELECT cr.cr_order_number
   FROM catalog_returns cr
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE regexp_like(cp.cp_description, '(?i)holiday')
     AND cp.cp_description LIKE '%holiday%'
),
common_orders AS (
   SELECT cr_order_number
   FROM gift_returns
   INTERSECT
   SELECT cr_order_number
   FROM holiday_page_returns
),
order_losses AS (
   SELECT
       cr.cr_order_number,
       cr.cr_returned_date_sk,
       d.d_date,
       d.d_weekend,
       SUM(cr.cr_net_loss) AS total_net_loss,
       regexp_extract(r.r_reason_id, '[A-Z]+') AS reason_prefix
   FROM catalog_returns cr
   JOIN common_orders co ON cr.cr_order_number = co.cr_order_number
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE d.d_weekend = 'Y'
   GROUP BY cr.cr_order_number,
            cr.cr_returned_date_sk,
            d.d_date,
            d.d_weekend,
            r.r_reason_id
)
SELECT
   ol.d_date,
   ol.total_net_loss,
   ol.reason_prefix,
   vt.status_label,
   concat(ol.reason_prefix, '_', vt.status_label) AS combined_label
FROM order_losses ol
CROSS JOIN (VALUES ('HIGH'), ('MEDIUM'), ('LOW')) AS vt(status_label)
ORDER BY ol.d_date DESC, ol.total_net_loss DESC
LIMIT 100

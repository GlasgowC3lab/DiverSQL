WITH agg AS (
  SELECT
    w.w_warehouse_name AS warehouse_name,
    w.w_country AS country,
    cp.cp_type AS catalog_type,
    cp.cp_catalog_page_number AS catalog_page_number,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
  JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
  WHERE cp.cp_catalog_number = 3
    AND cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
    AND w.w_country = 'United States'
    AND ca_ret.ca_country = 'United States'
  GROUP BY w.w_warehouse_name, w.w_country, cp.cp_type, cp.cp_catalog_page_number
  HAVING SUM(cr.cr_return_amount) > 500
)
SELECT
  warehouse_name,
  country,
  catalog_type,
  catalog_page_number,
  total_return_amount,
  total_net_loss,
  total_return_quantity,
  avg_return_quantity,
  return_cnt,
  RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank,
  NTILE(5) OVER (ORDER BY total_net_loss DESC) AS net_loss_quintile
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100

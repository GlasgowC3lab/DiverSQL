WITH catalog_state_agg AS (
  SELECT ca.ca_state AS state,
         COUNT(*) AS catalog_return_count,
         SUM(cr.cr_return_amount) AS catalog_total_return_amount,
         SUM(cr.cr_net_loss) AS catalog_total_net_loss,
         SUM(cr.cr_return_tax) AS catalog_total_return_tax
  FROM catalog_returns cr
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE cc.cc_tax_percentage > 0.05
  GROUP BY ca.ca_state
  HAVING SUM(cr.cr_return_amount) > 1000
),
web_state_agg AS (
  SELECT ca.ca_state AS state,
         COUNT(*) AS web_return_count,
         SUM(wr.wr_return_amt) AS web_total_return_amount,
         SUM(wr.wr_net_loss) AS web_total_net_loss
  FROM web_returns wr
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE wp.wp_type = 'product'
  GROUP BY ca.ca_state
  HAVING SUM(wr.wr_return_amt) > 500
)
SELECT COALESCE(c.state, w.state) AS state,
       COALESCE(c.catalog_return_count, 0) AS catalog_return_count,
       COALESCE(c.catalog_total_return_amount, 0) AS catalog_total_return_amount,
       COALESCE(c.catalog_total_net_loss, 0) AS catalog_total_net_loss,
       COALESCE(w.web_return_count, 0) AS web_return_count,
       COALESCE(w.web_total_return_amount, 0) AS web_total_return_amount,
       COALESCE(w.web_total_net_loss, 0) AS web_total_net_loss,
       (COALESCE(c.catalog_total_return_amount, 0) + COALESCE(w.web_total_return_amount, 0)) AS combined_total_return_amount,
       (COALESCE(c.catalog_total_net_loss, 0) + COALESCE(w.web_total_net_loss, 0)) AS combined_total_net_loss
FROM catalog_state_agg c
FULL OUTER JOIN web_state_agg w ON c.state = w.state
ORDER BY combined_total_return_amount DESC
LIMIT 20

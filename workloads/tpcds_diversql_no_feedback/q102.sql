WITH base AS (
  SELECT
    d.d_year AS year,
    r.r_reason_desc AS reason_desc,
    wsite.web_name AS web_site_name,
    cr.cr_return_amount AS cr_return_amount,
    ws.ws_net_paid_inc_tax AS ws_net_paid_inc_tax,
    inv.inv_quantity_on_hand AS inv_quantity_on_hand
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                     AND ws.ws_sold_time_sk = t.t_time_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
                     AND wp.wp_creation_date_sk = d.d_date_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
                        AND wsite.web_open_date_sk = d.d_date_sk
  JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND r.r_reason_desc LIKE '%purchase%'
    AND ws.ws_ext_discount_amt > 1000
    AND wsite.web_country = 'United States'
    AND inv.inv_quantity_on_hand < 500
    AND wp.wp_type = 'content'
    AND cr.cr_return_amount > 100
    AND cr.cr_reason_sk IN (
      SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%damaged%'
    )
)
SELECT
  year,
  reason_desc,
  web_site_name,
  SUM(cr_return_amount) AS total_return_amount,
  SUM(ws_net_paid_inc_tax) AS total_sales_amount,
  SUM(inv_quantity_on_hand) AS total_inventory_qty,
  RANK() OVER (ORDER BY SUM(cr_return_amount) DESC) AS return_amount_rank
FROM base
GROUP BY year, reason_desc, web_site_name
ORDER BY return_amount_rank
LIMIT 100

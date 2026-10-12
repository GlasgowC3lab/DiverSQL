WITH joined AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    p.p_promo_name,
    p.p_discount_active,
    ca.ca_state,
    cd.cd_credit_rating,
    sr.sr_net_loss,
    cr.cr_net_loss,
    wr.wr_net_loss
  FROM promotion p
  RIGHT OUTER JOIN store_sales ss
    ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
  LEFT JOIN catalog_returns cr
    ON ss.ss_customer_sk = cr.cr_refunded_customer_sk
       AND ss.ss_cdemo_sk = cr.cr_refunded_cdemo_sk
       AND ss.ss_addr_sk = cr.cr_refunded_addr_sk
  LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN warehouse wc
    ON cr.cr_warehouse_sk = wc.w_warehouse_sk
  LEFT JOIN web_sales ws
    ON c.c_customer_sk = ws.ws_bill_customer_sk
  LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
  LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
)
SELECT
  p_promo_name,
  COUNT(DISTINCT ss_ticket_number) AS num_sales,
  SUM(ss_ext_sales_price) AS total_sales,
  SUM(COALESCE(sr_net_loss, 0)) AS total_store_return_loss,
  SUM(COALESCE(cr_net_loss, 0)) AS total_catalog_return_loss,
  SUM(COALESCE(wr_net_loss, 0)) AS total_web_return_loss,
  AVG(ss_net_profit) AS avg_profit_per_sale
FROM joined
WHERE
  p_discount_active = 'Y'
  AND ca_state IN ('CA', 'TX', 'NY')
  AND cd_credit_rating = 'Good'
GROUP BY
  p_promo_name
HAVING
  SUM(ss_ext_sales_price) > 100000
ORDER BY
  total_sales DESC
LIMIT 100

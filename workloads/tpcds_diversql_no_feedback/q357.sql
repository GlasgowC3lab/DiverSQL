WITH unified AS (
  SELECT
    cc.cc_name,
    wsit.web_name,
    wp.wp_type,
    cd.cd_gender,
    cr.cr_net_loss,
    sr.sr_net_loss,
    wr.wr_net_loss,
    ws.ws_net_profit
  FROM call_center cc
  JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN customer_demographics cd ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
  JOIN household_demographics hd ON hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
  JOIN store_returns sr ON sr.sr_cdemo_sk = cd.cd_demo_sk AND sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
  WHERE cc.cc_state = 'CA'
    AND cr.cr_return_quantity > 5
    AND ws.ws_ext_wholesale_cost > 1000.00
    AND wp.wp_access_date_sk BETWEEN 2452550 AND 2452650
    AND ws.ws_web_site_sk IN (SELECT web_site_sk FROM web_site WHERE web_state = 'CA')

  UNION DISTINCT

  SELECT
    cc.cc_name,
    wsit.web_name,
    wp.wp_type,
    cd.cd_gender,
    cr.cr_net_loss,
    sr.sr_net_loss,
    wr.wr_net_loss,
    ws.ws_net_profit
  FROM call_center cc
  JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN customer_demographics cd ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
  JOIN household_demographics hd ON hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
  JOIN store_returns sr ON sr.sr_cdemo_sk = cd.cd_demo_sk AND sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN web_sales ws ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
  WHERE cc.cc_state = 'CA'
    AND sr.sr_return_quantity > 5
    AND wr.wr_return_quantity > 5
    AND wp.wp_type = 'Content'
    AND ws.ws_net_paid_inc_ship_tax > 2000.00
)
SELECT
  cc_name,
  web_name,
  wp_type,
  cd_gender,
  SUM(cr_net_loss) AS sum_cr_net_loss,
  SUM(sr_net_loss) AS sum_sr_net_loss,
  SUM(wr_net_loss) AS sum_wr_net_loss,
  SUM(ws_net_profit) AS sum_ws_net_profit,
  COUNT(*) AS txn_count
FROM unified
GROUP BY ROLLUP (cc_name, web_name, wp_type, cd_gender)
ORDER BY
  cc_name ASC NULLS FIRST,
  web_name ASC NULLS FIRST,
  wp_type ASC NULLS FIRST,
  cd_gender ASC NULLS FIRST
LIMIT 100

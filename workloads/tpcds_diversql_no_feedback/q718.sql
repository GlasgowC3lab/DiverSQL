SELECT
    ws.ws_order_number,
    ws.ws_net_paid,
    ws.ws_ship_date_sk,
    site.web_name,
    site.web_state
FROM tpcds.web_sales AS ws
JOIN tpcds.web_site AS site
  ON ws.ws_web_site_sk = site.web_site_sk
WHERE ws.ws_bill_addr_sk = 2272830
  AND site.web_suite_number = 'Suite 130'

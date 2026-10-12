WITH store_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_time_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        SUM(ss.ss_net_paid_inc_tax) AS store_net_paid_inc_tax,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_time_sk, ss.ss_hdemo_sk, ss.ss_addr_sk
)
SELECT
    s.s_store_id,
    s.s_state,
    t.t_hour,
    hd.hd_income_band_sk,
    SUM(sa.store_net_paid_inc_tax)               AS agg_store_net_paid,
    SUM(cs.cs_net_paid_inc_tax)                  AS agg_catalog_net_paid,
    SUM(ws.ws_net_paid_inc_tax)                  AS agg_web_net_paid,
    COUNT(DISTINCT cs.cs_order_number)           AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number)           AS web_orders,
    wp.wp_type,
    web.web_name
FROM store_agg sa
JOIN store s
  ON sa.ss_store_sk = s.s_store_sk
JOIN time_dim t
  ON sa.ss_sold_time_sk = t.t_time_sk
JOIN household_demographics hd
  ON sa.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON sa.ss_addr_sk = ca.ca_address_sk
JOIN catalog_sales cs
  ON cs.cs_sold_time_sk = t.t_time_sk
 AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
 AND cs.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk = cs.cs_item_sk
 AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
 AND cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN web_sales ws
  ON ws.ws_sold_time_sk = t.t_time_sk
 AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
 AND ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site web
  ON ws.ws_web_site_sk = web.web_site_sk
WHERE cr.cr_return_quantity IS NULL
  AND hd.hd_income_band_sk IN (3, 8, 10)
  AND hd.hd_dep_count <= 5
  AND s.s_state = 'TX'
  AND t.t_hour BETWEEN 9 AND 17
  AND ws.ws_net_paid_inc_ship > 1000
  AND ca.ca_country = 'United States'
GROUP BY
    s.s_store_id,
    s.s_state,
    t.t_hour,
    hd.hd_income_band_sk,
    wp.wp_type,
    web.web_name
HAVING SUM(sa.store_quantity) > 10
ORDER BY agg_store_net_paid DESC, s.s_store_id

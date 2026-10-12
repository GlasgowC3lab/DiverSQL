WITH sales_by_site AS (
    SELECT
        ws.ws_web_site_sk AS ws_web_site_sk,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_net_paid,
        AVG(ws.ws_ext_wholesale_cost) AS avg_wholesale_cost,
        COUNT(*) AS order_cnt
    FROM tpcds.web_sales ws
    JOIN tpcds.web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_ext_wholesale_cost > 1000
      AND ws.ws_ext_ship_cost < 500
      AND ws.ws_quantity >= 1
      AND ws.ws_net_paid_inc_ship_tax BETWEEN 500 AND 5000
      AND w.web_mkt_id IN (1, 2, 3)
      AND w.web_state = 'CA'
    GROUP BY ws.ws_web_site_sk
)
SELECT
    w.web_site_id,
    w.web_name,
    s.total_net_paid,
    s.avg_wholesale_cost,
    s.order_cnt
FROM sales_by_site s
JOIN tpcds.web_site w ON s.ws_web_site_sk = w.web_site_sk
WHERE s.total_net_paid > (
        SELECT AVG(total_net_paid) FROM sales_by_site
      )
  AND s.ws_web_site_sk NOT IN (
        SELECT ws.ws_web_site_sk FROM tpcds.web_sales ws WHERE ws.ws_quantity = 0
      )
  AND w.web_manager <> 'Robert Arnold'
  AND w.web_city = 'San Jose'
  AND w.web_tax_percentage < 0.09
  AND EXISTS (
        SELECT 1 FROM tpcds.web_sales ws2
        WHERE ws2.ws_web_site_sk = s.ws_web_site_sk
          AND ws2.ws_net_paid_inc_ship_tax > 2000
      )
ORDER BY s.total_net_paid DESC
LIMIT 100

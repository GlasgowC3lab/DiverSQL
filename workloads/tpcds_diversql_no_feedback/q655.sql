WITH promo_stats AS (
  SELECT
    p.p_promo_id AS p_id,
    p.p_promo_name AS p_name,
    cd.cd_gender,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    AVG(ws.ws_quantity) AS avg_qty,
    REGEXP_EXTRACT(c.c_email_address, '@(.+)$') AS email_domain
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  WHERE REGEXP_LIKE(p.p_promo_name, '(?i)discount')
    AND wp.wp_url LIKE '%sale%'
    AND ws.ws_quantity > (
      SELECT MAX(ws2.ws_quantity)
      FROM web_sales ws2
      WHERE ws2.ws_order_number = 1
    )
  GROUP BY p.p_promo_id,
           p.p_promo_name,
           cd.cd_gender,
           REGEXP_EXTRACT(c.c_email_address, '@(.+)$')
)
SELECT
  p_id,
  p_name,
  cd_gender,
  total_profit,
  sales_cnt,
  avg_qty,
  email_domain
FROM promo_stats
ORDER BY total_profit DESC
LIMIT 100

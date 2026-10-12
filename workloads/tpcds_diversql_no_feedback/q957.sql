WITH sampled_sales AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    hd.hd_buy_potential,
    sm.sm_type,
    regexp_extract(wp.wp_url, 'product/([0-9]+)', 1) AS product_id,
    concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    substring(wp.wp_url, 1, 15) AS url_prefix,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_paid) AS total_net_paid
FROM sampled_sales ws
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsi
    ON ws.ws_web_site_sk = wsi.web_site_sk
WHERE regexp_like(wp.wp_url, '/product/[0-9]+')
  AND (wsi.web_name LIKE '%Shop%' OR wsi.web_name LIKE '%Store%')
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
      )
GROUP BY
    hd.hd_buy_potential,
    sm.sm_type,
    regexp_extract(wp.wp_url, 'product/([0-9]+)', 1),
    concat(c.c_first_name, ' ', c.c_last_name),
    substring(wp.wp_url, 1, 15)
ORDER BY total_net_paid DESC
LIMIT 100

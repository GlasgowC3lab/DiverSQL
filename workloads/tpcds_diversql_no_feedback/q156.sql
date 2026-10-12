WITH avg_price AS (
    SELECT avg(ws_list_price) AS avg_price
    FROM web_sales
    WHERE ws_ship_mode_sk = 4
)
SELECT
    w.w_warehouse_name,
    ws_site.web_name,
    CONCAT('Domain: ', regexp_extract(wp.wp_url, '([^/]+)\\.com', 1)) AS domain_label,
    substring(wp.wp_url, 1, 20) AS url_prefix,
    sum(ws.ws_net_profit) AS total_net_profit,
    count(*) AS sales_count
FROM web_sales ws
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
WHERE regexp_like(wp.wp_url, '^https?://.*sale.*')
  AND t.t_hour BETWEEN 9 AND 17
  AND ws.ws_list_price > (SELECT avg_price FROM avg_price)
GROUP BY
    w.w_warehouse_name,
    ws_site.web_name,
    CONCAT('Domain: ', regexp_extract(wp.wp_url, '([^/]+)\\.com', 1)),
    substring(wp.wp_url, 1, 20)
ORDER BY total_net_profit DESC
LIMIT 100

WITH filtered_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_net_paid,
        wp.wp_web_page_id,
        wsit.web_site_sk,
        wsit.web_name,
        wp.wp_url
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE d.d_year = 2001
      AND regexp_like(wp.wp_url, '^https?://[^/]*example\\.com')
      AND wsit.web_name LIKE '%Retail%'
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_item_sk = ws.ws_item_sk
            AND sr.sr_returned_date_sk = ws.ws_sold_date_sk
      )
),
agg_sales AS (
    SELECT
        web_site_sk,
        web_name,
        wp_web_page_id,
        SUM(ws_net_paid) AS total_net_paid,
        CONCAT(web_name, ':', wp_web_page_id) AS site_page
    FROM filtered_sales
    GROUP BY web_site_sk, web_name, wp_web_page_id
)
SELECT
    a.web_site_sk,
    a.web_name,
    a.wp_web_page_id,
    a.total_net_paid,
    a.site_page,
    LAG(a.total_net_paid) OVER (PARTITION BY a.web_site_sk ORDER BY a.total_net_paid DESC) AS prev_total_net_paid
FROM agg_sales a
ORDER BY a.total_net_paid DESC
LIMIT 100

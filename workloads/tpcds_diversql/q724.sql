WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
intersected_stores AS (
    SELECT s_store_sk FROM store
    INTERSECT
    SELECT sr_store_sk FROM store_returns
)
SELECT
    s.s_store_name,
    d.d_year,
    p.p_promo_name,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(ss.ss_net_paid) AS total_store_net_paid,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    COUNT(r.r_reason_sk) AS return_reason_count,
    AVG(ss.ss_quantity) AS avg_store_quantity
FROM sampled_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
FULL OUTER JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND p.p_channel_tv = 'Y'
  AND r.r_reason_desc LIKE '%size%'
  AND ss.ss_net_paid > (
        SELECT MAX(ss2.ss_net_paid)
        FROM store_sales ss2
        WHERE ss2.ss_quantity = 1
    )
  AND s.s_store_sk IN (SELECT s_store_sk FROM intersected_stores)
GROUP BY s.s_store_name, d.d_year, p.p_promo_name
ORDER BY total_store_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY

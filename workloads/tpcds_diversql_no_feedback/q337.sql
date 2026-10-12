WITH ws_sample AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
)
SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    d.d_date,
    ws.ws_net_paid,
    ws.ws_quantity,
    p.p_promo_name,
    sm.sm_type AS ship_type,
    w.w_warehouse_name,
    ws_site.web_name AS site_name,
    sr.sr_net_loss,
    RANK() OVER (PARTITION BY d.d_year ORDER BY ws.ws_net_paid DESC) AS yearly_sales_rank,
    CASE
        WHEN p.p_discount_active = 'Y' THEN 'Discounted'
        ELSE 'Regular'
    END AS promo_category
FROM ws_sample ws
JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
WHERE
    d.d_year = 2002
    AND p.p_channel_event = 'N'
    AND sm.sm_type = 'AIR'
    AND w.w_state = 'CA'
    AND ws.ws_net_paid > 1000
ORDER BY yearly_sales_rank ASC, ws.ws_net_paid DESC
LIMIT 100

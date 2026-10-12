WITH sales_filtered AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_promo_sk,
        ws.ws_web_site_sk,
        ws.ws_bill_hdemo_sk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IS NOT NULL
)
SELECT
    ds.d_year,
    ds.d_month_seq,
    ws.web_site_id,
    ws.web_name,
    COUNT(DISTINCT p.p_promo_name) AS distinct_promotions,
    SUM(sf.ws_net_profit) AS total_net_profit,
    AVG(sf.ws_quantity) AS avg_quantity,
    AVG(hb.hd_income_band_sk) AS avg_income_band,
    AVG(hb.hd_vehicle_count) AS avg_vehicle_count,
    SUM(CASE WHEN cp.cp_catalog_page_number IS NOT NULL THEN sf.ws_quantity ELSE 0 END) AS catalog_page_quantity
FROM sales_filtered sf
JOIN date_dim ds ON sf.ws_sold_date_sk = ds.d_date_sk
JOIN web_site ws ON sf.ws_web_site_sk = ws.web_site_sk
JOIN promotion p ON sf.ws_promo_sk = p.p_promo_sk
JOIN date_dim dps ON p.p_start_date_sk = dps.d_date_sk
JOIN date_dim dpe ON p.p_end_date_sk = dpe.d_date_sk
JOIN household_demographics hb ON sf.ws_bill_hdemo_sk = hb.hd_demo_sk
LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = dps.d_date_sk AND cp.cp_end_date_sk = dpe.d_date_sk
WHERE ds.d_year = 2000
  AND p.p_discount_active = 'Y'
  AND p.p_channel_email = 'Y'
  AND ws.web_class = 'Consumer'
  AND (cp.cp_department = 'DEPARTMENT' OR cp.cp_department IS NULL)
GROUP BY
    ds.d_year,
    ds.d_month_seq,
    ws.web_site_id,
    ws.web_name
ORDER BY total_net_profit DESC
LIMIT 100

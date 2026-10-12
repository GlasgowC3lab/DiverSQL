WITH web_sales_enriched AS (
    SELECT
        d.d_quarter_name AS quarter,
        w.w_country AS country,
        hd.hd_buy_potential AS buy_potential,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_ext_discount_amt,
        wp.wp_image_count,
        t.t_hour,
        d_page_creation.d_date AS page_creation_date,
        d_site_open.d_date AS site_open_date
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN date_dim d_page_creation ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
    JOIN date_dim d_site_open ON site.web_open_date_sk = d_site_open.d_date_sk
    WHERE d.d_holiday = 'N'
      AND d_page_creation.d_date >= DATE '2000-01-01'
      AND d_site_open.d_date <= DATE '2005-01-01'
)
SELECT
    quarter,
    country,
    buy_potential,
    SUM(ws_net_profit) AS total_net_profit,
    SUM(ws_quantity) AS total_quantity,
    AVG(ws_ext_discount_amt) AS avg_discount_amount,
    AVG(wp_image_count) AS avg_images_per_page,
    AVG(t_hour) AS avg_sale_hour
FROM web_sales_enriched
GROUP BY quarter, country, buy_potential
HAVING SUM(ws_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100

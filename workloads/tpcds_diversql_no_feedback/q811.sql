WITH filtered_sales AS (
    SELECT
        dd.d_year,
        CONCAT(i.i_brand, '-', i.i_color) AS brand_color,
        cd.cd_gender,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE regexp_like(i.i_item_desc, '\\d{3}')
      AND wp.wp_url LIKE '%example%'
      AND substring(i.i_product_name, 1, 5) = 'Ultra'
)
SELECT
    fs.d_year,
    fs.brand_color,
    SUM(CASE WHEN fs.cd_gender = 'F' THEN fs.ws_net_profit ELSE 0 END) AS profit_female,
    SUM(fs.ws_net_profit) AS total_profit,
    COUNT(*) AS sales_count
FROM filtered_sales fs
GROUP BY
    fs.d_year,
    fs.brand_color
ORDER BY total_profit DESC
LIMIT 10

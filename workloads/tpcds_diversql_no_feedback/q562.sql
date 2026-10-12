WITH sales_agg AS (
    SELECT
        ws_warehouse_sk,
        ws_web_site_sk,
        SUM(ws_net_profit) AS total_profit,
        SUM(ws_coupon_amt) AS total_coupon,
        COUNT(*) AS sales_count
    FROM web_sales
    WHERE ws_coupon_amt > 0
    GROUP BY ws_warehouse_sk, ws_web_site_sk
)
SELECT
    w.w_city,
    w.w_state,
    ws.web_name,
    s.total_profit,
    s.sales_count,
    CONCAT('Profit_', CAST(s.total_profit AS VARCHAR)) AS profit_label,
    REGEXP_EXTRACT(ws.web_mkt_desc, '(?i)(technical|political)') AS market_keyword
FROM sales_agg s
JOIN warehouse w ON s.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site ws ON s.ws_web_site_sk = ws.web_site_sk
WHERE
    w.w_street_name LIKE '%Park%'
    AND REGEXP_LIKE(ws.web_mkt_desc, '(?i)technical')
    AND s.total_coupon > (
        SELECT AVG(ws2.ws_coupon_amt)
        FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = s.ws_web_site_sk
    )
ORDER BY s.total_profit DESC
LIMIT 20

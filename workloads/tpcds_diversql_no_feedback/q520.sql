WITH sales_store AS (
    SELECT
        ss.ss_ticket_number AS order_key,
        s.s_store_name AS channel_name,
        'Store' AS channel_type,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    FULL OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_quantity > 0
),
web_channel AS (
    SELECT
        ws.ws_order_number AS order_key,
        w.web_name AS channel_name,
        'Web' AS channel_type,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    FULL OUTER JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_ext_tax > 50.00
),
combined_sales AS (
    SELECT order_key, channel_name, channel_type, net_profit FROM sales_store
    UNION ALL
    SELECT order_key, channel_name, channel_type, net_profit FROM web_channel
)
SELECT
    cs.order_key,
    cs.channel_name,
    cs.channel_type,
    cs.net_profit
FROM combined_sales cs
WHERE cs.order_key IS NOT NULL
  AND cs.order_key NOT IN (
        SELECT c.cs_order_number
        FROM catalog_sales c
    )
ORDER BY cs.net_profit DESC, cs.order_key
LIMIT 100

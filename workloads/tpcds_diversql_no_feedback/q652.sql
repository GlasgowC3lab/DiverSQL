WITH catalog_sub AS (
    SELECT
        d.d_date AS sale_date,
        i.i_item_id,
        cs.cs_net_profit AS net_profit,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        'catalog' AS src
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2001
      AND i.i_category_id = 5
      AND NOT EXISTS (
            SELECT 1 FROM catalog_returns cr
            WHERE cr.cr_order_number = cs.cs_order_number
        )
),
web_sub AS (
    SELECT
        d.d_date AS sale_date,
        i.i_item_id,
        ws.ws_net_profit AS net_profit,
        CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        'web' AS src
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year = 2001
      AND w.web_state = 'CA'
      AND i.i_category_id = 5
      AND NOT EXISTS (
            SELECT 1 FROM catalog_returns cr
            WHERE cr.cr_order_number = ws.ws_order_number
        )
)
SELECT *
FROM catalog_sub
UNION ALL
SELECT *
FROM web_sub
ORDER BY net_profit DESC
LIMIT 100

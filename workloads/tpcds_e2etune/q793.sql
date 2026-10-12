WITH store_agg AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        s.s_store_name AS store_name,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ss.ss_quantity) AS store_qty,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM
        store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE
        s.s_state = 'CO'
        AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY
        ss.ss_item_sk,
        s.s_store_name
),
web_agg AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        site.web_name AS web_name,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(ws.ws_quantity) AS web_qty,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM
        web_sales ws
        JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    WHERE
        site.web_state = 'CO'
        AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY
        ws.ws_item_sk,
        site.web_name
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    COALESCE(s.store_name, 'N/A') AS store_name,
    COALESCE(w.web_name, 'N/A') AS web_name,
    COALESCE(s.store_profit, 0) AS store_profit,
    COALESCE(w.web_profit, 0) AS web_profit,
    COALESCE(s.store_qty, 0) AS store_qty,
    COALESCE(w.web_qty, 0) AS web_qty,
    (COALESCE(s.store_profit, 0) - COALESCE(w.web_profit, 0)) AS profit_diff,
    ROW_NUMBER() OVER (ORDER BY (COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0)) DESC) AS rank_total_profit
FROM
    item i
    LEFT JOIN store_agg s ON i.i_item_sk = s.item_sk
    LEFT JOIN web_agg w ON i.i_item_sk = w.item_sk
WHERE
    i.i_category = 'Electronics'
    AND (COALESCE(s.store_profit, 0) + COALESCE(w.web_profit, 0)) > 10000
ORDER BY
    profit_diff DESC
LIMIT 50

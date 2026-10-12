WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_warehouse_sk,
        ws.ws_web_page_sk,
        ws.ws_sold_date_sk
    FROM tpcds.web_sales ws
    WHERE ws.ws_net_profit > 0
),
returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_net_loss,
        wr.wr_reason_sk,
        wr.wr_web_page_sk,
        wr.wr_returned_date_sk
    FROM tpcds.web_returns wr
    WHERE wr.wr_net_loss > 0
)
SELECT
    COALESCE(wh.w_warehouse_name, 'UNKNOWN') AS warehouse_name,
    wh.w_county,
    CONCAT(wh.w_city, ', ', wh.w_state) AS location,
    rsn.r_reason_desc,
    COUNT(DISTINCT COALESCE(s.ws_order_number, ret.wr_order_number)) AS total_orders,
    SUM(COALESCE(s.ws_ext_sales_price, 0)) AS total_sales,
    SUM(COALESCE(ret.wr_net_loss, 0)) AS total_return_loss,
    SUM(COALESCE(s.ws_net_profit, 0)) - SUM(COALESCE(ret.wr_net_loss, 0)) AS net_contribution,
    CASE
        WHEN REGEXP_LIKE(wh.w_warehouse_name, '^WH[0-9]+') THEN 'PatternMatch'
        ELSE 'NoMatch'
    END AS warehouse_name_pattern,
    REGEXP_EXTRACT(pg.wp_url, 'https?://([^/]+)/', 1) AS url_domain,
    SUBSTRING(wh.w_warehouse_name, 1, 4) AS warehouse_prefix
FROM sales s
FULL OUTER JOIN returns ret
    ON s.ws_order_number = ret.wr_order_number
LEFT JOIN tpcds.warehouse wh
    ON s.ws_warehouse_sk = wh.w_warehouse_sk
LEFT JOIN tpcds.web_page pg
    ON COALESCE(s.ws_web_page_sk, ret.wr_web_page_sk) = pg.wp_web_page_sk
LEFT JOIN tpcds.reason rsn
    ON ret.wr_reason_sk = rsn.r_reason_sk
WHERE
    (wh.w_warehouse_name LIKE '%Warehouse%' OR wh.w_warehouse_name IS NULL)
    AND (REGEXP_LIKE(pg.wp_url, '^https?://[a-z]+\\.com') OR pg.wp_url IS NULL)
GROUP BY
    wh.w_warehouse_name,
    wh.w_county,
    wh.w_city,
    wh.w_state,
    rsn.r_reason_desc,
    CASE
        WHEN REGEXP_LIKE(wh.w_warehouse_name, '^WH[0-9]+') THEN 'PatternMatch'
        ELSE 'NoMatch'
    END,
    REGEXP_EXTRACT(pg.wp_url, 'https?://([^/]+)/', 1),
    SUBSTRING(wh.w_warehouse_name, 1, 4)
ORDER BY net_contribution DESC
LIMIT 100

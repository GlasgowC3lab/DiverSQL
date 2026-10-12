WITH store_sales_on_open AS (
    SELECT
        d.d_year AS year,
        ca.ca_state AS state,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        COUNT(DISTINCT ss.ss_item_sk) AS store_distinct_items,
        AVG(cc.cc_tax_percentage) AS avg_tax_pct
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE cc.cc_tax_percentage > 0.05
    GROUP BY d.d_year, ca.ca_state
),
web_sales_on_open AS (
    SELECT
        d.d_year AS year,
        ca.ca_state AS state,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        COUNT(DISTINCT ws.ws_item_sk) AS web_distinct_items,
        AVG(cc.cc_tax_percentage) AS avg_tax_pct
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE cc.cc_tax_percentage > 0.05
    GROUP BY d.d_year, ca.ca_state
)
SELECT
    s.year,
    s.state,
    s.store_net_profit + w.web_net_profit AS total_net_profit,
    s.store_sales + w.web_sales AS total_sales,
    s.store_distinct_items + w.web_distinct_items AS total_distinct_items,
    s.avg_tax_pct AS avg_call_center_tax_pct
FROM store_sales_on_open s
JOIN web_sales_on_open w
    ON s.year = w.year
    AND s.state = w.state
WHERE (s.store_net_profit + w.web_net_profit) > 100000
ORDER BY total_net_profit DESC
LIMIT 100

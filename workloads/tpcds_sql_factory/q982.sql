WITH profit_by_product_state AS (
    SELECT
        ws_site.web_state AS state,
        ws.ws_item_sk AS product_id,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ws.ws_ext_sales_price) = 0 THEN 0
             ELSE ROUND(SUM(ws.ws_net_profit) * 100.0 / SUM(ws.ws_ext_sales_price), 2)
        END AS profit_margin_pct
    FROM web_sales ws
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year >= year(current_date) - 1
    GROUP BY ws_site.web_state, ws.ws_item_sk
), ranked_products AS (
    SELECT
        state,
        product_id,
        total_profit,
        total_sales,
        sales_cnt,
        profit_margin_pct,
        RANK() OVER (PARTITION BY state ORDER BY total_profit DESC) AS profit_rank,
        DENSE_RANK() OVER (PARTITION BY state ORDER BY profit_margin_pct DESC) AS margin_rank
    FROM profit_by_product_state
)
SELECT
    state,
    product_id,
    total_profit,
    total_sales,
    sales_cnt,
    profit_margin_pct,
    profit_rank,
    margin_rank,
    CASE
        WHEN profit_margin_pct >= 30 THEN 'High'
        WHEN profit_margin_pct >= 15 THEN 'Medium'
        ELSE 'Low'
    END AS margin_category
FROM ranked_products
WHERE profit_rank <= 5
ORDER BY state, profit_rank

WITH date_year AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year BETWEEN 1999 AND 2001
),
store_data AS (
    SELECT d.d_year,
           'Store' AS channel,
           s.s_store_sk AS entity_sk,
           SUM(ss.ss_net_profit) AS net_profit,
           SUM(ss.ss_ext_sales_price) AS revenue,
           COUNT(DISTINCT ss.ss_ticket_number) AS orders,
           SUM(COALESCE(p.p_cost, 0)) AS promo_cost
    FROM store_sales ss
    JOIN date_year d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY d.d_year, s.s_store_sk
),
catalog_data AS (
    SELECT d.d_year,
           'Catalog' AS channel,
           ca.cc_call_center_sk AS entity_sk,
           SUM(cs.cs_net_profit) AS net_profit,
           SUM(cs.cs_ext_sales_price) AS revenue,
           COUNT(DISTINCT cs.cs_order_number) AS orders,
           SUM(COALESCE(p.p_cost, 0)) AS promo_cost
    FROM catalog_sales cs
    JOIN date_year d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center ca ON cs.cs_call_center_sk = ca.cc_call_center_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY d.d_year, ca.cc_call_center_sk
),
web_data AS (
    SELECT d.d_year,
           'Web' AS channel,
           w.web_site_sk AS entity_sk,
           SUM(ws.ws_net_profit) AS net_profit,
           SUM(ws.ws_ext_sales_price) AS revenue,
           COUNT(DISTINCT ws.ws_order_number) AS orders,
           SUM(COALESCE(p.p_cost, 0)) AS promo_cost
    FROM web_sales ws
    JOIN date_year d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY d.d_year, w.web_site_sk
),
combined AS (
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM web_data
),
agg AS (
    SELECT
        d_year,
        channel,
        entity_sk,
        SUM(net_profit) AS total_net_profit,
        SUM(revenue) AS total_revenue,
        SUM(orders) AS total_orders,
        SUM(promo_cost) AS total_promo_cost
    FROM combined
    GROUP BY GROUPING SETS (
        (d_year, channel, entity_sk),
        (d_year, channel),
        (d_year)
    )
)
SELECT
    d_year,
    channel,
    entity_sk,
    total_net_profit,
    total_revenue,
    total_orders,
    total_promo_cost,
    ROUND(total_net_profit / NULLIF(total_revenue, 0) * 100, 2) AS profit_margin_pct,
    ROUND(total_promo_cost / NULLIF(total_revenue, 0) * 100, 2) AS promo_cost_pct,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY d_year, channel, entity_sk

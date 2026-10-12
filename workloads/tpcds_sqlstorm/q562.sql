WITH raw_sales AS (
    SELECT 'store' AS channel,
           ss.ss_sold_date_sk AS sold_date_sk,
           i.i_category,
           s.s_store_id AS location_id,
           s.s_state AS location_state,
           ss.ss_quantity AS quantity,
           ss.ss_ext_sales_price AS ext_sales_price,
           ss.ss_net_profit AS net_profit,
           ss.ss_promo_sk AS promo_sk,
           date_format(d.d_date, '%Y-%m') AS month_ym
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2000

    UNION ALL

    SELECT 'catalog' AS channel,
           cs.cs_sold_date_sk AS sold_date_sk,
           i.i_category,
           cc.cc_call_center_id AS location_id,
           cc.cc_state AS location_state,
           cs.cs_quantity AS quantity,
           cs.cs_ext_sales_price AS ext_sales_price,
           cs.cs_net_profit AS net_profit,
           cs.cs_promo_sk AS promo_sk,
           date_format(d.d_date, '%Y-%m') AS month_ym
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2000

    UNION ALL

    SELECT 'web' AS channel,
           ws.ws_sold_date_sk AS sold_date_sk,
           i.i_category,
           w.web_name AS location_id,
           w.web_state AS location_state,
           ws.ws_quantity AS quantity,
           ws.ws_ext_sales_price AS ext_sales_price,
           ws.ws_net_profit AS net_profit,
           ws.ws_promo_sk AS promo_sk,
           date_format(d.d_date, '%Y-%m') AS month_ym
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year = 2000
),
monthly_agg AS (
    SELECT
        channel,
        location_id,
        location_state,
        i_category,
        month_ym,
        SUM(ext_sales_price) AS total_sales,
        SUM(net_profit) AS total_profit,
        SUM(quantity) AS total_quantity,
        SUM(CASE WHEN promo_sk IS NOT NULL THEN 1 ELSE 0 END) AS promo_count
    FROM raw_sales
    GROUP BY channel, location_id, location_state, i_category, month_ym
)
SELECT
    channel,
    location_id,
    location_state,
    i_category,
    month_ym,
    total_sales,
    total_profit,
    total_quantity,
    promo_count,
    LAG(total_profit) OVER (PARTITION BY channel, location_id, i_category ORDER BY month_ym) AS prev_month_profit,
    CASE
        WHEN LAG(total_profit) OVER (PARTITION BY channel, location_id, i_category ORDER BY month_ym) = 0 THEN NULL
        ELSE (total_profit - LAG(total_profit) OVER (PARTITION BY channel, location_id, i_category ORDER BY month_ym)) / LAG(total_profit) OVER (PARTITION BY channel, location_id, i_category ORDER BY month_ym)
    END AS profit_mom_pct,
    ROW_NUMBER() OVER (PARTITION BY channel, location_id, i_category ORDER BY total_profit DESC) AS profit_rank
FROM monthly_agg
ORDER BY channel, location_id, i_category, month_ym

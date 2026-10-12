WITH sales_union AS (
    SELECT
        ss_sold_date_sk AS date_sk,
        ss_item_sk AS item_sk,
        ss_store_sk AS channel_sk,
        'store' AS channel,
        ss_quantity AS quantity,
        ss_net_paid AS net_paid,
        ss_net_paid_inc_tax AS net_paid_inc_tax,
        ss_net_profit AS net_profit
    FROM store_sales
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        cs_call_center_sk,
        'catalog',
        cs_quantity,
        cs_net_paid,
        cs_net_paid_inc_tax,
        cs_net_profit
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_web_site_sk,
        'web',
        ws_quantity,
        ws_net_paid,
        ws_net_paid_inc_tax,
        ws_net_profit
    FROM web_sales
),
sales_enriched AS (
    SELECT
        su.date_sk,
        su.item_sk,
        su.channel_sk,
        su.channel,
        su.quantity,
        su.net_paid,
        su.net_paid_inc_tax,
        su.net_profit,
        d.d_year,
        i.i_category,
        i.i_class
    FROM sales_union su
    JOIN date_dim d ON su.date_sk = d.d_date_sk
    JOIN item i ON su.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
),
aggregated_sales AS (
    SELECT
        d_year,
        channel,
        channel_sk,
        i_category,
        i_class,
        SUM(quantity) AS total_quantity,
        SUM(net_paid) AS total_net_paid,
        SUM(net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(net_profit) AS total_net_profit
    FROM sales_enriched
    GROUP BY d_year, channel, channel_sk, i_category, i_class
),
profit_with_yoy AS (
    SELECT
        a.*,
        LAG(total_net_profit) OVER (PARTITION BY channel, i_category, i_class ORDER BY d_year) AS prior_year_profit,
        CASE
            WHEN LAG(total_net_profit) OVER (PARTITION BY channel, i_category, i_class ORDER BY d_year) = 0 THEN NULL
            ELSE (total_net_profit - LAG(total_net_profit) OVER (PARTITION BY channel, i_category, i_class ORDER BY d_year)) / LAG(total_net_profit) OVER (PARTITION BY channel, i_category, i_class ORDER BY d_year)
        END AS yoy_profit_change
    FROM aggregated_sales a
),
ranked_sales AS (
    SELECT
        p.*,
        ROW_NUMBER() OVER (PARTITION BY d_year, channel ORDER BY total_net_profit DESC) AS profit_rank,
        AVG(total_net_profit) OVER (PARTITION BY d_year, channel) AS avg_profit_per_category
    FROM profit_with_yoy p
),
channel_names AS (
    SELECT
        s.s_store_sk AS channel_sk,
        s.s_store_name AS channel_name,
        'store' AS channel
    FROM store s
    UNION ALL
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        'catalog'
    FROM call_center cc
    UNION ALL
    SELECT
        ws.web_site_sk,
        ws.web_name,
        'web'
    FROM web_site ws
)
SELECT
    rs.d_year,
    rs.channel,
    cn.channel_name,
    rs.i_category,
    rs.i_class,
    rs.total_quantity,
    rs.total_net_paid,
    rs.total_net_paid_inc_tax,
    rs.total_net_profit,
    rs.yoy_profit_change,
    rs.profit_rank,
    rs.avg_profit_per_category,
    rs.total_net_profit - rs.avg_profit_per_category AS profit_vs_avg
FROM ranked_sales rs
LEFT JOIN channel_names cn
    ON rs.channel = cn.channel
    AND rs.channel_sk = cn.channel_sk
WHERE rs.profit_rank <= 5
ORDER BY rs.d_year, rs.channel, rs.profit_rank

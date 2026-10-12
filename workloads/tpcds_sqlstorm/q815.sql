WITH sales_union AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        'store' AS channel,
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS ext_sales,
        s.s_state AS state,
        s.s_city AS city
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        'catalog' AS channel,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS ext_sales,
        cc.cc_state AS state,
        cc.cc_city AS city
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        'web' AS channel,
        ws.ws_net_profit AS net_profit,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS ext_sales,
        w.web_state AS state,
        w.web_city AS city
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
monthly_agg AS (
    SELECT
        d_year,
        d_month_seq,
        channel,
        i_category,
        i_brand,
        SUM(net_profit) AS total_net_profit,
        SUM(ext_sales) AS total_sales,
        SUM(quantity) AS total_quantity
    FROM sales_union
    GROUP BY d_year, d_month_seq, channel, i_category, i_brand
)
SELECT
    d_year,
    d_month_seq,
    channel,
    i_category,
    i_brand,
    total_net_profit,
    total_sales,
    total_quantity,
    LAG(total_net_profit) OVER (PARTITION BY channel, i_category, i_brand ORDER BY d_year, d_month_seq) AS prev_month_net_profit,
    CASE
        WHEN LAG(total_net_profit) OVER (PARTITION BY channel, i_category, i_brand ORDER BY d_year, d_month_seq) = 0 THEN NULL
        ELSE (total_net_profit - LAG(total_net_profit) OVER (PARTITION BY channel, i_category, i_brand ORDER BY d_year, d_month_seq))
             / LAG(total_net_profit) OVER (PARTITION BY channel, i_category, i_brand ORDER BY d_year, d_month_seq) * 100
    END AS mom_percent_change,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq, channel ORDER BY total_net_profit DESC) AS category_rank
FROM monthly_agg
ORDER BY d_year, d_month_seq, channel, category_rank
LIMIT 200

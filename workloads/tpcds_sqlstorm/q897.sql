WITH combined_sales AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_store_sk AS store_sk,
        i.i_category AS category,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_sales_price AS ext_sales,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cc.cc_call_center_sk AS store_sk,
        i.i_category AS category,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_sales_price AS ext_sales,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_warehouse_sk AS store_sk,
        i.i_category AS category,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_sales_price AS ext_sales,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
monthly_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        COALESCE(s.s_store_name, c.cc_name, w.w_warehouse_name) AS location_name,
        cs.sales_channel,
        cs.category,
        SUM(cs.net_profit) AS total_net_profit,
        SUM(cs.ext_sales) AS total_sales,
        COUNT(*) AS transaction_count
    FROM combined_sales cs
    LEFT JOIN date_dim d ON cs.sold_date_sk = d.d_date_sk
    LEFT JOIN store s ON cs.store_sk = s.s_store_sk
    LEFT JOIN call_center c ON cs.store_sk = c.cc_call_center_sk
    LEFT JOIN warehouse w ON cs.store_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
    GROUP BY
        d.d_year,
        d.d_month_seq,
        COALESCE(s.s_store_name, c.cc_name, w.w_warehouse_name),
        cs.sales_channel,
        cs.category
    HAVING SUM(cs.net_profit) > 0
)
SELECT
    d_year,
    d_month_seq,
    location_name,
    sales_channel,
    category,
    total_net_profit,
    total_sales,
    transaction_count,
    LAG(total_net_profit) OVER (PARTITION BY location_name, sales_channel, category ORDER BY d_month_seq) AS prev_month_profit,
    (total_net_profit - LAG(total_net_profit) OVER (PARTITION BY location_name, sales_channel, category ORDER BY d_month_seq))
        / NULLIF(LAG(total_net_profit) OVER (PARTITION BY location_name, sales_channel, category ORDER BY d_month_seq), 0) AS mom_growth_ratio,
    RANK() OVER (PARTITION BY d_month_seq ORDER BY total_net_profit DESC) AS profit_rank
FROM monthly_sales
ORDER BY d_year, d_month_seq, profit_rank
LIMIT 100

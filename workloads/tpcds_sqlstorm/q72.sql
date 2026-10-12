WITH sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        'store' AS channel,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS ext_sales_price,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        'catalog' AS channel,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        'web' AS channel,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    channel,
    total_sales,
    total_profit,
    total_quantity,
    transaction_count,
    avg_sales_per_txn,
    profit_margin,
    category_rank
FROM (
    SELECT
        d_year,
        d_month_seq,
        i_category,
        channel,
        SUM(ext_sales_price) AS total_sales,
        SUM(net_profit) AS total_profit,
        SUM(quantity) AS total_quantity,
        COUNT(*) AS transaction_count,
        AVG(ext_sales_price) AS avg_sales_per_txn,
        SUM(CASE WHEN net_profit > 0 THEN net_profit ELSE 0 END) / NULLIF(SUM(ext_sales_price), 0) AS profit_margin,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY SUM(ext_sales_price) DESC) AS category_rank
    FROM sales
    GROUP BY d_year, d_month_seq, i_category, channel
) ranked_sales
WHERE category_rank <= 5
ORDER BY d_year, d_month_seq, category_rank

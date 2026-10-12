WITH sales AS (
    SELECT
        d.d_year AS sales_year,
        d.d_quarter_name AS sales_quarter,
        cc.cc_state AS state,
        'catalog' AS channel,
        i.i_category AS category,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        CASE WHEN cs.cs_ext_list_price > 0 THEN cs.cs_ext_discount_amt / cs.cs_ext_list_price END AS discount_ratio,
        cs.cs_ext_sales_price AS ext_sales_price
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    UNION ALL
    SELECT
        d.d_year AS sales_year,
        d.d_quarter_name AS sales_quarter,
        s.s_state AS state,
        'store' AS channel,
        i.i_category AS category,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        CASE WHEN ss.ss_ext_list_price > 0 THEN ss.ss_ext_discount_amt / ss.ss_ext_list_price END AS discount_ratio,
        ss.ss_ext_sales_price AS ext_sales_price
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    UNION ALL
    SELECT
        d.d_year AS sales_year,
        d.d_quarter_name AS sales_quarter,
        ws_site.web_state AS state,
        'web' AS channel,
        i.i_category AS category,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        CASE WHEN ws.ws_ext_list_price > 0 THEN ws.ws_ext_discount_amt / ws.ws_ext_list_price END AS discount_ratio,
        ws.ws_ext_sales_price AS ext_sales_price
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
),
aggregated AS (
    SELECT
        sales_year,
        sales_quarter,
        state,
        channel,
        category,
        SUM(quantity) AS total_quantity,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        AVG(discount_ratio) AS avg_discount_ratio,
        SUM(ext_sales_price) AS total_sales_amount
    FROM sales
    GROUP BY GROUPING SETS (
        (sales_year, sales_quarter, state, channel, category),
        (sales_year, sales_quarter, state, channel),
        (sales_year, sales_quarter, state),
        (sales_year, sales_quarter)
    )
    HAVING SUM(net_profit) > 0
),
ranked AS (
    SELECT
        a.*,
        ROW_NUMBER() OVER (PARTITION BY sales_year, sales_quarter, state, channel ORDER BY total_net_profit DESC) AS profit_rank
    FROM aggregated a
    WHERE a.category IS NOT NULL
),
combined AS (
    SELECT *
    FROM ranked
    WHERE profit_rank <= 5
    UNION ALL
    SELECT
        sales_year,
        sales_quarter,
        state,
        channel,
        NULL AS category,
        total_quantity,
        total_net_paid,
        total_net_profit,
        avg_discount_ratio,
        total_sales_amount,
        NULL AS profit_rank
    FROM aggregated
    WHERE category IS NULL
)
SELECT *
FROM combined
ORDER BY sales_year, sales_quarter, state, channel, profit_rank
LIMIT 200

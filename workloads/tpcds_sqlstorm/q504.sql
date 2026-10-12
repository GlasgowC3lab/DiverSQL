WITH sales_store AS (
    SELECT
        ss.ss_sold_date_sk,
        d.d_date,
        ss.ss_store_sk,
        s.s_store_name,
        ss.ss_item_sk,
        i.i_category,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk, ss.ss_item_sk ORDER BY d.d_date DESC) AS rn_item_latest
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),
sales_web AS (
    SELECT
        ws.ws_sold_date_sk,
        d.d_date,
        ws.ws_web_page_sk,
        wp.wp_url,
        ws.ws_item_sk,
        i.i_category,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_page_sk, ws.ws_item_sk ORDER BY d.d_date DESC) AS rn_item_latest
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),
sales_catalog AS (
    SELECT
        cs.cs_sold_date_sk,
        d.d_date,
        cs.cs_catalog_page_sk,
        cp.cp_catalog_number,
        cs.cs_item_sk,
        i.i_category,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_catalog_page_sk, cs.cs_item_sk ORDER BY d.d_date DESC) AS rn_item_latest
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),
combined_sales AS (
    SELECT
        'Store' AS channel,
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.d_date,
        ss.ss_store_sk AS entity_sk,
        ss.s_store_name AS entity_name,
        ss.ss_item_sk AS item_sk,
        ss.i_category,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_sales_price AS ext_sales_price,
        ss.rn_item_latest
    FROM sales_store ss

    UNION ALL

    SELECT
        'Web' AS channel,
        ws.ws_sold_date_sk,
        ws.d_date,
        ws.ws_web_page_sk,
        wp.wp_url,
        ws.ws_item_sk,
        ws.i_category,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.rn_item_latest
    FROM sales_web ws
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk

    UNION ALL

    SELECT
        'Catalog' AS channel,
        cs.cs_sold_date_sk,
        cs.d_date,
        cs.cs_catalog_page_sk,
        CAST(cp.cp_catalog_number AS varchar) || ':' || CAST(cp.cp_type AS varchar),
        cs.cs_item_sk,
        cs.i_category,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.rn_item_latest
    FROM sales_catalog cs
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
),
latest_sales AS (
    SELECT *
    FROM combined_sales
    WHERE rn_item_latest = 1
),
returns_aggregated AS (
    SELECT
        COALESCE(sr.sr_returned_date_sk, cr.cr_returned_date_sk, wr.wr_returned_date_sk) AS returned_date_sk,
        COALESCE(d.d_date, d2.d_date, d3.d_date) AS returned_date,
        COALESCE(sr.sr_store_sk, cr.cr_call_center_sk, wr.wr_web_page_sk) AS entity_sk,
        CASE
            WHEN sr.sr_store_sk IS NOT NULL THEN 'Store'
            WHEN cr.cr_call_center_sk IS NOT NULL THEN 'Catalog'
            WHEN wr.wr_web_page_sk IS NOT NULL THEN 'Web'
            ELSE 'Unknown'
        END AS channel,
        COALESCE(sr.sr_item_sk, cr.cr_item_sk, wr.wr_item_sk) AS item_sk,
        SUM(
            COALESCE(sr.sr_return_amt, 0) + COALESCE(sr.sr_return_tax, 0) +
            COALESCE(cr.cr_return_amount, 0) + COALESCE(cr.cr_return_tax, 0) +
            COALESCE(wr.wr_return_amt, 0) + COALESCE(wr.wr_return_tax, 0)
        ) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    FULL OUTER JOIN catalog_returns cr
        ON sr.sr_returned_date_sk = cr.cr_returned_date_sk
        AND sr.sr_item_sk = cr.cr_item_sk
    FULL OUTER JOIN web_returns wr
        ON sr.sr_returned_date_sk = wr.wr_returned_date_sk
        AND sr.sr_item_sk = wr.wr_item_sk
    LEFT JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
    LEFT JOIN date_dim d3 ON wr.wr_returned_date_sk = d3.d_date_sk
    WHERE COALESCE(sr.sr_returned_date_sk, cr.cr_returned_date_sk, wr.wr_returned_date_sk) IS NOT NULL
    GROUP BY
        COALESCE(sr.sr_returned_date_sk, cr.cr_returned_date_sk, wr.wr_returned_date_sk),
        COALESCE(d.d_date, d2.d_date, d3.d_date),
        COALESCE(sr.sr_store_sk, cr.cr_call_center_sk, wr.wr_web_page_sk),
        CASE
            WHEN sr.sr_store_sk IS NOT NULL THEN 'Store'
            WHEN cr.cr_call_center_sk IS NOT NULL THEN 'Catalog'
            WHEN wr.wr_web_page_sk IS NOT NULL THEN 'Web'
            ELSE 'Unknown'
        END,
        COALESCE(sr.sr_item_sk, cr.cr_item_sk, wr.wr_item_sk)
),
sales_with_returns AS (
    SELECT
        ls.channel,
        ls.sold_date_sk,
        ls.d_date AS sold_date,
        ls.entity_sk,
        ls.entity_name,
        ls.item_sk,
        ls.i_category,
        ls.quantity,
        ls.net_paid,
        ls.net_profit,
        ls.ext_sales_price,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        COALESCE(ra.return_cnt, 0) AS return_cnt,
        (ls.net_profit - COALESCE(ra.total_return_amount, 0)) AS adjusted_profit,
        SUM(ls.net_profit - COALESCE(ra.total_return_amount, 0)) OVER (
            PARTITION BY ls.channel, ls.i_category
            ORDER BY ls.d_date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS rolling_30d_profit,
        CASE
            WHEN ls.ext_sales_price > 0 THEN (COALESCE(ra.total_return_amount, 0) / ls.ext_sales_price) * 100
            ELSE NULL
        END AS return_pct_of_sales,
        CASE
            WHEN ls.net_profit / NULLIF(ls.ext_sales_price, 0) > 0.30 THEN 'High'
            ELSE 'Standard'
        END AS margin_indicator,
        CONCAT(ls.channel, ':', COALESCE(ls.entity_name, CAST(ls.entity_sk AS varchar)), ':', CAST(ls.item_sk AS varchar)) AS sales_key
    FROM latest_sales ls
    LEFT JOIN returns_aggregated ra
        ON ls.channel = ra.channel
        AND ls.entity_sk = ra.entity_sk
        AND ls.item_sk = ra.item_sk
        AND ls.sold_date_sk = ra.returned_date_sk
    WHERE ls.quantity > 0
),
final_result AS (
    SELECT
        channel,
        i_category,
        DATE_TRUNC('month', sold_date) AS month,
        SUM(quantity) AS total_quantity,
        SUM(net_paid) AS total_net_paid,
        SUM(adjusted_profit) AS total_adjusted_profit,
        SUM(rolling_30d_profit) AS sum_rolling_30d_profit,
        AVG(return_pct_of_sales) AS avg_return_pct,
        COUNT(DISTINCT CASE WHEN margin_indicator = 'High' THEN sales_key END) AS high_margin_items,
        ARRAY_JOIN(ARRAY_AGG(DISTINCT sales_key), ',') AS sales_key_list
    FROM sales_with_returns
    GROUP BY
        channel,
        i_category,
        DATE_TRUNC('month', sold_date)
)
SELECT *
FROM final_result

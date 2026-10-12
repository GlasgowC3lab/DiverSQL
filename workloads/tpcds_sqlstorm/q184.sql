WITH
date_dim_filtered AS (
    SELECT d_date_sk, d_year, d_month_seq, d_date
    FROM date_dim
    WHERE d_year BETWEEN 1999 AND 2001
),
store_sales_agg AS (
    SELECT
        ss_store_sk,
        d.d_year AS sales_year,
        SUM(ss_net_profit) AS store_sales_profit,
        SUM(ss_quantity) AS store_sales_qty,
        COUNT(DISTINCT ss_ticket_number) AS sales_txns
    FROM store_sales ss
    JOIN date_dim_filtered d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss_store_sk, d.d_year
),
store_returns_agg AS (
    SELECT
        sr_store_sk,
        d.d_year AS return_year,
        SUM(sr_net_loss) AS store_returns_loss,
        SUM(sr_return_quantity) AS returns_qty,
        COUNT(DISTINCT sr_ticket_number) AS returns_txns
    FROM store_returns sr
    JOIN date_dim_filtered d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr_store_sk, d.d_year
),
store_combined AS (
    SELECT
        COALESCE(s.ss_store_sk, r.sr_store_sk) AS s_store_sk,
        COALESCE(s.sales_year, r.return_year) AS year,
        COALESCE(s.store_sales_profit, 0) - COALESCE(r.store_returns_loss, 0) AS net_profit,
        COALESCE(s.store_sales_qty, 0) - COALESCE(r.returns_qty, 0) AS net_quantity,
        COALESCE(s.sales_txns, 0) - COALESCE(r.returns_txns, 0) AS net_transactions
    FROM store_sales_agg s
    FULL OUTER JOIN store_returns_agg r
        ON s.ss_store_sk = r.sr_store_sk
        AND s.sales_year = r.return_year
),
store_with_details AS (
    SELECT
        sc.s_store_sk,
        sc.year,
        sc.net_profit,
        sc.net_quantity,
        sc.net_transactions,
        st.s_store_name,
        st.s_city,
        st.s_state,
        CONCAT(st.s_store_name, ' (', st.s_city, ', ', st.s_state, ')') AS store_full_name,
        CASE
            WHEN sc.net_profit > 0 THEN 'Profit'
            WHEN sc.net_profit < 0 THEN 'Loss'
            ELSE 'Break-even'
        END AS profit_status,
        ROW_NUMBER() OVER (PARTITION BY sc.year ORDER BY sc.net_profit DESC) AS profit_rank,
        (SELECT COALESCE(prev.net_profit, 0)
         FROM store_combined prev
         WHERE prev.s_store_sk = sc.s_store_sk
           AND prev.year = sc.year - 1) AS prev_year_profit,
        CASE
            WHEN (SELECT COALESCE(prev.net_profit, 0)
                  FROM store_combined prev
                  WHERE prev.s_store_sk = sc.s_store_sk
                    AND prev.year = sc.year - 1) = 0 THEN NULL
            ELSE (sc.net_profit -
                 (SELECT COALESCE(prev.net_profit, 0)
                  FROM store_combined prev
                  WHERE prev.s_store_sk = sc.s_store_sk
                    AND prev.year = sc.year - 1))
                 / NULLIF((SELECT COALESCE(prev.net_profit, 0)
                  FROM store_combined prev
                  WHERE prev.s_store_sk = sc.s_store_sk
                    AND prev.year = sc.year - 1), 0)
        END AS yoy_profit_growth
    FROM store_combined sc
    LEFT JOIN store st ON sc.s_store_sk = st.s_store_sk
    WHERE sc.year IS NOT NULL
),
web_sales_agg AS (
    SELECT
        ws.ws_web_page_sk,
        d.d_year AS sales_year,
        SUM(ws.ws_net_profit) AS web_sales_profit,
        SUM(ws.ws_quantity) AS web_sales_qty,
        COUNT(DISTINCT ws.ws_order_number) AS web_txns
    FROM web_sales ws
    JOIN date_dim_filtered d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_web_page_sk, d.d_year
),
web_returns_agg AS (
    SELECT
        wr.wr_web_page_sk,
        d.d_year AS return_year,
        SUM(wr.wr_net_loss) AS web_returns_loss,
        SUM(wr.wr_return_quantity) AS web_returns_qty,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_txns
    FROM web_returns wr
    JOIN date_dim_filtered d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY wr.wr_web_page_sk, d.d_year
),
web_combined AS (
    SELECT
        COALESCE(w.ws_web_page_sk, r.wr_web_page_sk) AS ws_web_page_sk,
        COALESCE(w.sales_year, r.return_year) AS year,
        COALESCE(w.web_sales_profit, 0) - COALESCE(r.web_returns_loss, 0) AS net_profit,
        COALESCE(w.web_sales_qty, 0) - COALESCE(r.web_returns_qty, 0) AS net_quantity,
        COALESCE(w.web_txns, 0) - COALESCE(r.web_return_txns, 0) AS net_transactions
    FROM web_sales_agg w
    FULL OUTER JOIN web_returns_agg r
        ON w.ws_web_page_sk = r.wr_web_page_sk
        AND w.sales_year = r.return_year
),
combined_channels AS (
    SELECT
        'store' AS channel,
        s.s_store_sk AS entity_id,
        s.year,
        s.net_profit,
        s.net_quantity,
        s.net_transactions,
        s.store_full_name AS entity_name,
        s.profit_status,
        s.profit_rank,
        s.yoy_profit_growth
    FROM store_with_details s
    UNION ALL
    SELECT
        'web' AS channel,
        w.ws_web_page_sk AS entity_id,
        w.year,
        w.net_profit,
        w.net_quantity,
        w.net_transactions,
        wp.wp_url AS entity_name,
        CASE
            WHEN w.net_profit > 0 THEN 'Profit'
            WHEN w.net_profit < 0 THEN 'Loss'
            ELSE 'Break-even'
        END AS profit_status,
        NULL AS profit_rank,
        NULL AS yoy_profit_growth
    FROM web_combined w
    LEFT JOIN web_page wp ON w.ws_web_page_sk = wp.wp_web_page_sk
    WHERE w.year IS NOT NULL
)
SELECT
    channel,
    entity_id,
    year,
    net_profit,
    net_quantity,
    net_transactions,
    entity_name,
    profit_status,
    profit_rank,
    yoy_profit_growth,
    PERCENT_RANK() OVER (PARTITION BY year ORDER BY net_profit) AS profit_percentile,
    CASE
        WHEN profit_status = 'Profit' AND yoy_profit_growth IS NOT NULL AND yoy_profit_growth > 0.2
            THEN CONCAT('High Growth: ', entity_name)
        WHEN profit_status = 'Profit' AND yoy_profit_growth IS NOT NULL AND yoy_profit_growth BETWEEN 0 AND 0.2
            THEN CONCAT('Moderate Growth: ', entity_name)
        WHEN profit_status = 'Loss'
            THEN CONCAT('Loss: ', COALESCE(entity_name, 'Unknown'))
        ELSE 'Neutral/Insufficient Data'
    END AS growth_category
FROM combined_channels
WHERE year = (SELECT MAX(d_year) FROM date_dim_filtered)
ORDER BY net_profit DESC
LIMIT 50

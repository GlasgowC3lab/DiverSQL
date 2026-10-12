WITH store_sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ss.ss_store_sk, ss.ss_item_sk
), store_returns_agg AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        sr.sr_item_sk AS item_sk,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY sr.sr_store_sk, sr.sr_item_sk
), store_combined AS (
    SELECT
        COALESCE(s.store_sk, r.store_sk) AS store_sk,
        COALESCE(s.item_sk, r.item_sk) AS item_sk,
        COALESCE(s.total_quantity, 0) AS total_quantity_sold,
        COALESCE(r.total_return_qty, 0) AS total_quantity_returned,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        COALESCE(s.total_profit, 0) - COALESCE(r.total_return_loss, 0) AS net_profit
    FROM store_sales_agg s
    FULL OUTER JOIN store_returns_agg r
        ON s.store_sk = r.store_sk AND s.item_sk = r.item_sk
), store_ranked AS (
    SELECT
        sc.*,
        ROW_NUMBER() OVER (PARTITION BY sc.store_sk ORDER BY sc.net_profit DESC) AS rank_in_store,
        (SELECT AVG(sc2.net_profit) FROM store_combined sc2 WHERE sc2.store_sk = sc.store_sk) AS avg_store_profit
    FROM store_combined sc
    WHERE COALESCE(sc.total_quantity_sold, 0) > 0
), store_top5 AS (
    SELECT
        sr.store_sk,
        st.s_store_name,
        i.i_item_id,
        i.i_product_name,
        sr.total_quantity_sold,
        sr.total_sales,
        sr.total_return_loss,
        sr.net_profit,
        sr.rank_in_store,
        CASE WHEN sr.net_profit > sr.avg_store_profit THEN 'Above Avg' ELSE 'Below Avg' END AS profit_flag,
        CONCAT(st.s_store_name, ' | ', i.i_item_id, ' | ', COALESCE(i.i_product_name, 'N/A')) AS description
    FROM store_ranked sr
    JOIN store st ON sr.store_sk = st.s_store_sk
    JOIN item i ON sr.item_sk = i.i_item_sk
    WHERE sr.rank_in_store <= 5
), web_sales_agg AS (
    SELECT
        ws.ws_web_page_sk AS web_page_sk,
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_web_page_sk, ws.ws_item_sk
), web_returns_agg AS (
    SELECT
        wr.wr_web_page_sk AS web_page_sk,
        wr.wr_item_sk AS item_sk,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY wr.wr_web_page_sk, wr.wr_item_sk
), web_combined AS (
    SELECT
        COALESCE(ws.web_page_sk, wr.web_page_sk) AS web_page_sk,
        COALESCE(ws.item_sk, wr.item_sk) AS item_sk,
        COALESCE(ws.total_quantity, 0) AS total_quantity_sold,
        COALESCE(wr.total_return_qty, 0) AS total_quantity_returned,
        COALESCE(ws.total_sales, 0) AS total_sales,
        COALESCE(wr.total_return_loss, 0) AS total_return_loss,
        COALESCE(ws.total_profit, 0) - COALESCE(wr.total_return_loss, 0) AS net_profit
    FROM web_sales_agg ws
    FULL OUTER JOIN web_returns_agg wr
        ON ws.web_page_sk = wr.web_page_sk AND ws.item_sk = wr.item_sk
), web_ranked AS (
    SELECT
        wc.*,
        ROW_NUMBER() OVER (PARTITION BY wc.web_page_sk ORDER BY wc.net_profit DESC) AS rank_in_page,
        (SELECT AVG(wc2.net_profit) FROM web_combined wc2 WHERE wc2.web_page_sk = wc.web_page_sk) AS avg_page_profit
    FROM web_combined wc
    WHERE COALESCE(wc.total_quantity_sold, 0) > 0
), web_top5 AS (
    SELECT
        wr.web_page_sk,
        wp.wp_url,
        i.i_item_id,
        i.i_product_name,
        wr.total_quantity_sold,
        wr.total_sales,
        wr.total_return_loss,
        wr.net_profit,
        wr.rank_in_page,
        CASE WHEN wr.net_profit > wr.avg_page_profit THEN 'Above Avg' ELSE 'Below Avg' END AS profit_flag,
        CONCAT(wp.wp_url, ' | ', i.i_item_id, ' | ', COALESCE(i.i_product_name, 'N/A')) AS description
    FROM web_ranked wr
    JOIN web_page wp ON wr.web_page_sk = wp.wp_web_page_sk
    JOIN item i ON wr.item_sk = i.i_item_sk
    WHERE wr.rank_in_page <= 5
)
SELECT *
FROM store_top5
UNION ALL
SELECT *
FROM web_top5
ORDER BY net_profit DESC
LIMIT 100

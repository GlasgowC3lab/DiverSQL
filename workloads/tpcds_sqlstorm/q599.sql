WITH store_agg AS (
    SELECT
        s.ss_item_sk AS item_sk,
        SUM(s.ss_net_profit) AS store_net_profit,
        SUM(s.ss_ext_discount_amt) AS store_discount,
        COUNT(*) AS store_txn_cnt
    FROM store_sales s
    JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.ss_item_sk
),
web_agg AS (
    SELECT
        w.ws_item_sk AS item_sk,
        SUM(w.ws_net_profit) AS web_net_profit,
        SUM(w.ws_ext_discount_amt) AS web_discount,
        COUNT(*) AS web_txn_cnt
    FROM web_sales w
    JOIN date_dim d ON w.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY w.ws_item_sk
),
catalog_agg AS (
    SELECT
        c.cs_item_sk AS item_sk,
        SUM(c.cs_net_profit) AS catalog_net_profit,
        SUM(c.cs_ext_discount_amt) AS catalog_discount,
        COUNT(*) AS catalog_txn_cnt
    FROM catalog_sales c
    JOIN date_dim d ON c.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY c.cs_item_sk
),
item_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) AS total_net_profit,
        COALESCE(s.store_discount, 0) + COALESCE(w.web_discount, 0) + COALESCE(c.catalog_discount, 0) AS total_discount,
        COALESCE(s.store_txn_cnt, 0) + COALESCE(w.web_txn_cnt, 0) + COALESCE(c.catalog_txn_cnt, 0) AS total_txn_cnt,
        COALESCE(s.store_net_profit, 0) AS store_net_profit,
        COALESCE(w.web_net_profit, 0) AS web_net_profit,
        COALESCE(c.catalog_net_profit, 0) AS catalog_net_profit,
        COALESCE(s.store_discount, 0) AS store_discount,
        COALESCE(w.web_discount, 0) AS web_discount,
        COALESCE(c.catalog_discount, 0) AS catalog_discount,
        COALESCE(s.store_txn_cnt, 0) AS store_txn_cnt,
        COALESCE(w.web_txn_cnt, 0) AS web_txn_cnt,
        COALESCE(c.catalog_txn_cnt, 0) AS catalog_txn_cnt
    FROM item i
    LEFT JOIN store_agg s ON i.i_item_sk = s.item_sk
    LEFT JOIN web_agg w ON i.i_item_sk = w.item_sk
    LEFT JOIN catalog_agg c ON i.i_item_sk = c.item_sk
),
ranked_items AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS rank
    FROM item_agg
    WHERE total_net_profit > 0
)
SELECT
    rank,
    i_item_sk,
    i_product_name,
    total_net_profit,
    ROUND(store_net_profit / total_net_profit * 100, 2) AS store_pct,
    ROUND(web_net_profit / total_net_profit * 100, 2) AS web_pct,
    ROUND(catalog_net_profit / total_net_profit * 100, 2) AS catalog_pct,
    total_discount,
    ROUND(total_discount / total_net_profit * 100, 2) AS discount_to_profit_pct,
    total_txn_cnt
FROM ranked_items
WHERE rank <= 10
ORDER BY rank

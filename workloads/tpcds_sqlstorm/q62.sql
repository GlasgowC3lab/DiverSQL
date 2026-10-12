WITH
unified_sales AS (
    SELECT cs_sold_date_sk AS sold_date_sk, cs_item_sk AS item_sk, cs_quantity AS quantity, cs_net_profit AS net_profit
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk, ss_item_sk, ss_quantity, ss_net_profit
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_net_profit
    FROM web_sales
),
agg_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        concat(CAST(d.d_year AS VARCHAR), '-', lpad(CAST(d.d_moy AS VARCHAR), 2, '0')) AS year_month,
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        SUM(s.quantity) AS total_quantity,
        SUM(s.net_profit) AS total_net_profit,
        COUNT(*) AS transaction_count
    FROM unified_sales s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY
        d.d_year,
        d.d_month_seq,
        d.d_moy,
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_category
),
ranked_sales AS (
    SELECT
        a.*,
        ROW_NUMBER() OVER (PARTITION BY a.year_month ORDER BY a.total_net_profit DESC) AS profit_rank,
        AVG(a.total_net_profit) OVER (PARTITION BY a.i_item_sk ORDER BY a.month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3m,
        COALESCE(
            (SELECT SUM(prev.total_net_profit)
             FROM agg_sales prev
             WHERE prev.i_item_sk = a.i_item_sk
               AND prev.month_seq = a.month_seq - 1), 0) AS prev_month_net_profit,
        concat(a.i_product_name, ' ', a.i_brand, ' (', a.i_category, ')') AS product_label,
        CASE
            WHEN a.total_net_profit IS NULL THEN 'No Profit'
            WHEN a.total_net_profit < 0 THEN 'Loss'
            ELSE 'Profit'
        END AS profit_status
    FROM agg_sales a
),
cd_map AS (
    SELECT
        ss.ss_item_sk,
        MIN(c.c_current_cdemo_sk) AS cd_sk
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY ss.ss_item_sk
)
SELECT
    r.year_month,
    r.i_item_sk,
    r.product_label,
    r.i_category,
    r.total_quantity,
    r.total_net_profit,
    r.profit_rank,
    r.moving_avg_3m,
    r.prev_month_net_profit,
    r.profit_status,
    COALESCE(r.transaction_count, 0) AS transaction_count,
    cd.cd_gender,
    cd.cd_credit_rating
FROM ranked_sales r
LEFT JOIN cd_map cm ON r.i_item_sk = cm.ss_item_sk
LEFT JOIN customer_demographics cd ON cm.cd_sk = cd.cd_demo_sk
WHERE r.profit_rank <= 10
ORDER BY r.year_month, r.profit_rank

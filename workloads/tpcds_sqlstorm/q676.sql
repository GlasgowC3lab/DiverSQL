WITH sales_union AS (
    SELECT cs_sold_date_sk AS sold_date_sk,
           cs_item_sk AS item_sk,
           cs_net_profit AS net_profit
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_item_sk,
           ss_net_profit
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_net_profit
    FROM web_sales
), aggregated AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(s.net_profit) AS total_net_profit,
        AVG(s.net_profit) AS avg_net_profit,
        COUNT(*) AS sales_cnt
    FROM sales_union s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category
    HAVING SUM(s.net_profit) > 0
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    total_net_profit,
    avg_net_profit,
    sales_cnt,
    SUM(total_net_profit) OVER (PARTITION BY d_year ORDER BY d_month_seq) AS ytd_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS category_rank
FROM aggregated
ORDER BY d_year, d_month_seq, category_rank

WITH date_sales AS (
    SELECT
        d.d_date AS sale_date,
        d.d_year,
        d.d_month_seq,
        d.d_moy,
        CAST('store' AS VARCHAR) AS channel,
        ss.ss_item_sk AS item_sk,
        sum(ss.ss_net_paid) AS total_net_paid,
        sum(ss.ss_net_profit) AS total_net_profit,
        sum(ss.ss_quantity) AS total_quantity,
        avg(ss.ss_sales_price) AS avg_sales_price
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date, d.d_year, d.d_month_seq, d.d_moy, ss.ss_item_sk
),
catalog_sales_agg AS (
    SELECT
        d.d_date AS sale_date,
        d.d_year,
        d.d_month_seq,
        d.d_moy,
        CAST('catalog' AS VARCHAR) AS channel,
        cs.cs_item_sk AS item_sk,
        sum(cs.cs_net_paid) AS total_net_paid,
        sum(cs.cs_net_profit) AS total_net_profit,
        sum(cs.cs_quantity) AS total_quantity,
        avg(cs.cs_sales_price) AS avg_sales_price
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date, d.d_year, d.d_month_seq, d.d_moy, cs.cs_item_sk
),
web_sales_agg AS (
    SELECT
        d.d_date AS sale_date,
        d.d_year,
        d.d_month_seq,
        d.d_moy,
        CAST('web' AS VARCHAR) AS channel,
        ws.ws_item_sk AS item_sk,
        sum(ws.ws_net_paid) AS total_net_paid,
        sum(ws.ws_net_profit) AS total_net_profit,
        sum(ws.ws_quantity) AS total_quantity,
        avg(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date, d.d_year, d.d_month_seq, d.d_moy, ws.ws_item_sk
),
combined_sales_raw AS (
    SELECT * FROM date_sales
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
sales_without_zero_paid AS (
    SELECT * FROM combined_sales_raw
    EXCEPT
    SELECT * FROM combined_sales_raw WHERE total_net_paid = 0
),
ranked_sales AS (
    SELECT
        cs.*,
        row_number() OVER (PARTITION BY cs.sale_date ORDER BY cs.total_net_profit DESC) AS profit_rank,
        dense_rank() OVER (PARTITION BY cs.sale_date, cs.channel ORDER BY cs.total_net_paid DESC) AS paid_rank,
        CASE
            WHEN cs.total_net_profit < 0 THEN 'Loss'
            WHEN cs.total_net_profit >= 0 AND cs.total_net_profit < cs.total_net_paid * 0.1 THEN 'LowProfit'
            ELSE 'GoodProfit'
        END AS profit_category,
        CONCAT('Item_', CAST(cs.item_sk AS VARCHAR)) AS item_label,
        COALESCE(
            (SELECT sum(ss2.ss_net_profit)
             FROM store_sales ss2
             JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
             WHERE ss2.ss_item_sk = cs.item_sk
               AND d2.d_date = date_add('day', -1, cs.sale_date)
            ),
            0
        ) AS prev_day_store_profit,
        i.i_brand AS item_brand
    FROM sales_without_zero_paid cs
    LEFT JOIN item i ON i.i_item_sk = cs.item_sk
),
final_agg AS (
    SELECT
        sale_date,
        channel,
        profit_category,
        count(*) AS product_count,
        sum(total_net_paid) AS sum_net_paid,
        sum(total_net_profit) AS sum_net_profit,
        avg(total_quantity) AS avg_quantity,
        max(prev_day_store_profit) AS max_prev_day_store_profit,
        min(prev_day_store_profit) AS min_prev_day_store_profit,
        avg(CASE WHEN profit_rank <= 10 THEN total_net_profit END) AS top10_avg_profit,
        sum(CASE WHEN profit_category = 'Loss' THEN total_net_profit ELSE 0 END) AS total_loss_amount
    FROM ranked_sales
    WHERE (item_brand IS NULL AND total_net_profit < 0) OR (item_brand IS NOT NULL AND total_net_profit >= 0)
    GROUP BY GROUPING SETS ((sale_date, channel, profit_category), (sale_date, channel), (sale_date))
)
SELECT
    sale_date,
    channel,
    profit_category,
    product_count,
    sum_net_paid,
    sum_net_profit,
    avg_quantity,
    round(sum_net_profit / nullif(sum_net_paid, 0), 4) AS profit_margin,
    max_prev_day_store_profit,
    min_prev_day_store_profit,
    top10_avg_profit,
    total_loss_amount,
    CASE
        WHEN sum_net_profit > 0 THEN 'POSITIVE'
        WHEN sum_net_profit < 0 THEN 'NEGATIVE'
        ELSE 'ZERO'
    END AS profit_flag,
    CONCAT(
        CAST(EXTRACT(year FROM sale_date) AS VARCHAR), '-',
        LPAD(CAST(EXTRACT(month FROM sale_date) AS VARCHAR), 2, '0'), '-',
        LPAD(CAST(EXTRACT(day FROM sale_date) AS VARCHAR), 2, '0')
    ) AS sale_date_str
FROM final_agg
ORDER BY sale_date DESC, channel, profit_category

WITH sales_by_channel AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'catalog' AS channel,
        i.i_category,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        SUM(cs.cs_net_profit) AS profit,
        SUM(cs.cs_quantity) AS quantity,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        AVG(cs.cs_sales_price) AS avg_price
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        'store' AS channel,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_net_profit) AS profit,
        SUM(ss.ss_quantity) AS quantity,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders,
        AVG(ss.ss_sales_price) AS avg_price
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq,
        'web' AS channel,
        i.i_category,
        SUM(ws.ws_ext_sales_price) AS sales_amount,
        SUM(ws.ws_net_profit) AS profit,
        SUM(ws.ws_quantity) AS quantity,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        AVG(ws.ws_sales_price) AS avg_price
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
ranked_sales AS (
    SELECT
        d_year,
        d_month_seq,
        channel,
        i_category,
        sales_amount,
        profit,
        quantity,
        orders,
        avg_price,
        RANK() OVER (PARTITION BY d_year, channel ORDER BY sales_amount DESC) AS category_sales_rank,
        SUM(sales_amount) OVER (PARTITION BY d_year, channel) AS total_sales_by_channel,
        sales_amount / SUM(sales_amount) OVER (PARTITION BY d_year, channel) AS sales_share
    FROM sales_by_channel
)
SELECT
    d_year,
    d_month_seq,
    channel,
    i_category,
    sales_amount,
    profit,
    quantity,
    orders,
    avg_price,
    category_sales_rank,
    total_sales_by_channel,
    ROUND(sales_share * 100, 2) AS sales_share_pct
FROM ranked_sales
WHERE category_sales_rank <= 5
ORDER BY d_year, channel, category_sales_rank

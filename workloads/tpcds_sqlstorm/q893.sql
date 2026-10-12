WITH
sales AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
        'store' AS channel,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_profit AS net_profit,
        ss.ss_net_paid AS net_paid,
        ss.ss_ext_sales_price AS ext_sales_price
    FROM store_sales ss
    UNION ALL
    SELECT cs.cs_sold_date_sk AS date_sk,
        'catalog' AS channel,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS net_profit,
        cs.cs_net_paid AS net_paid,
        cs.cs_ext_sales_price AS ext_sales_price
    FROM catalog_sales cs
    UNION ALL
    SELECT ws.ws_sold_date_sk AS date_sk,
        'web' AS channel,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS net_profit,
        ws.ws_net_paid AS net_paid,
        ws.ws_ext_sales_price AS ext_sales_price
    FROM web_sales ws
),
returns AS (
    SELECT sr.sr_returned_date_sk AS date_sk,
        'store' AS channel,
        sr.sr_item_sk AS item_sk,
        sr.sr_return_quantity AS quantity,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
    UNION ALL
    SELECT cr.cr_returned_date_sk AS date_sk,
        'catalog' AS channel,
        cr.cr_item_sk AS item_sk,
        cr.cr_return_quantity AS quantity,
        cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    UNION ALL
    SELECT wr.wr_returned_date_sk AS date_sk,
        'web' AS channel,
        wr.wr_item_sk AS item_sk,
        wr.wr_return_quantity AS quantity,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
),
sales_agg AS (
    SELECT d.d_year,
        d.d_month_seq,
        s.channel,
        i.i_category,
        i.i_brand,
        SUM(s.quantity) AS total_quantity_sold,
        SUM(s.net_profit) AS total_net_profit,
        SUM(s.net_paid) AS total_net_paid,
        SUM(s.ext_sales_price) AS total_sales_amount
    FROM sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, s.channel, i.i_category, i.i_brand
),
returns_agg AS (
    SELECT d.d_year,
        d.d_month_seq,
        r.channel,
        i.i_category,
        i.i_brand,
        SUM(r.quantity) AS total_quantity_returned,
        SUM(r.net_loss) AS total_return_loss
    FROM returns r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, r.channel, i.i_category, i.i_brand
),
combined AS (
    SELECT sa.d_year,
        sa.d_month_seq,
        sa.channel,
        sa.i_category,
        sa.i_brand,
        sa.total_quantity_sold,
        COALESCE(ra.total_quantity_returned, 0) AS total_quantity_returned,
        sa.total_net_profit,
        COALESCE(ra.total_return_loss, 0) AS total_return_loss,
        sa.total_net_profit - COALESCE(ra.total_return_loss, 0) AS net_profit_after_returns,
        sa.total_sales_amount
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.d_year = ra.d_year
        AND sa.d_month_seq = ra.d_month_seq
        AND sa.channel = ra.channel
        AND sa.i_category = ra.i_category
        AND sa.i_brand = ra.i_brand
),
ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq, channel ORDER BY net_profit_after_returns DESC) AS profit_rank
    FROM combined
)
SELECT d_year,
    d_month_seq,
    channel,
    i_category,
    i_brand,
    total_quantity_sold,
    total_quantity_returned,
    total_sales_amount,
    total_net_profit,
    total_return_loss,
    net_profit_after_returns,
    profit_rank
FROM ranked
WHERE profit_rank <= 5
ORDER BY d_year, d_month_seq, channel, profit_rank

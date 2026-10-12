WITH sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_quantity AS quantity,
           cs.cs_ext_sales_price AS ext_sales_price,
           cs.cs_net_profit AS net_profit,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_quantity,
           ss.ss_ext_sales_price,
           ss.ss_net_profit,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_quantity,
           ws.ws_ext_sales_price,
           ws.ws_net_profit,
           'web' AS channel
    FROM web_sales ws
),
returns AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           cr.cr_item_sk AS item_sk,
           cr.cr_return_quantity AS quantity,
           cr.cr_return_amount AS return_amount,
           cr.cr_net_loss AS net_loss,
           'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_returned_date_sk,
           sr.sr_item_sk,
           sr.sr_return_quantity,
           sr.sr_return_amt,
           sr.sr_net_loss,
           'store' AS channel
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           wr.wr_item_sk,
           wr.wr_return_quantity,
           wr.wr_return_amt,
           wr.wr_net_loss,
           'web' AS channel
    FROM web_returns wr
),
item_dim AS (
    SELECT i.i_item_sk,
           i.i_category,
           i.i_class,
           i.i_brand,
           i.i_manufact,
           i.i_color,
           i.i_size
    FROM item i
),
date_dim_filtered AS (
    SELECT d.d_date_sk,
           d.d_year,
           d.d_quarter_seq,
           d.d_month_seq,
           d.d_date
    FROM date_dim d
    WHERE d.d_year BETWEEN 1999 AND 2001
),
sales_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        i.i_class,
        s.channel,
        SUM(s.ext_sales_price) AS total_sales,
        SUM(s.net_profit) AS total_profit,
        SUM(s.quantity) AS total_quantity
    FROM sales s
    JOIN date_dim_filtered d ON s.date_sk = d.d_date_sk
    JOIN item_dim i ON s.item_sk = i.i_item_sk
    GROUP BY
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        i.i_class,
        s.channel
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        i.i_class,
        r.channel,
        SUM(r.return_amount) AS total_returns,
        SUM(r.net_loss) AS total_return_loss,
        SUM(r.quantity) AS total_return_quantity
    FROM returns r
    JOIN date_dim_filtered d ON r.date_sk = d.d_date_sk
    JOIN item_dim i ON r.item_sk = i.i_item_sk
    GROUP BY
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        i.i_class,
        r.channel
),
combined AS (
    SELECT
        s.d_year,
        s.d_quarter_seq,
        s.i_category,
        s.i_class,
        s.channel,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        s.total_sales - COALESCE(r.total_returns, 0) AS net_sales,
        s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit,
        s.total_quantity - COALESCE(r.total_return_quantity, 0) AS net_quantity
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.d_year = r.d_year
       AND s.d_quarter_seq = r.d_quarter_seq
       AND s.i_category = r.i_category
       AND s.i_class = r.i_class
       AND s.channel = r.channel
),
ranked AS (
    SELECT
        d_year,
        d_quarter_seq,
        i_category,
        i_class,
        channel,
        net_sales,
        net_profit,
        net_quantity,
        CASE WHEN net_sales > 0 THEN net_profit / net_sales ELSE NULL END AS profit_margin,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_quarter_seq, channel ORDER BY net_profit DESC) AS profit_rank,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_quarter_seq, channel ORDER BY net_sales DESC) AS sales_rank
    FROM combined
)
SELECT
    d_year,
    d_quarter_seq,
    i_category,
    i_class,
    channel,
    net_sales,
    net_profit,
    profit_margin,
    net_quantity,
    profit_rank,
    sales_rank
FROM ranked
WHERE profit_rank <= 5
ORDER BY d_year, d_quarter_seq, channel, profit_rank

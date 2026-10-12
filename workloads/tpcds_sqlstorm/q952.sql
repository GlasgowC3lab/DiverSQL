WITH sales AS (
    SELECT
        ss_sold_date_sk AS sold_date_sk,
        ss_item_sk AS item_sk,
        ss_net_paid AS net_paid,
        ss_net_profit AS net_profit,
        ss_quantity AS quantity,
        'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        cs_net_paid,
        cs_net_profit,
        cs_quantity,
        'catalog'
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_net_paid,
        ws_net_profit,
        ws_quantity,
        'web'
    FROM web_sales
),
returns AS (
    SELECT
        sr_returned_date_sk AS returned_date_sk,
        sr_item_sk AS item_sk,
        sr_return_amt AS return_amount,
        sr_net_loss AS net_loss,
        sr_return_quantity AS quantity,
        'store' AS channel
    FROM store_returns
    UNION ALL
    SELECT
        cr_returned_date_sk,
        cr_item_sk,
        cr_return_amount,
        cr_net_loss,
        cr_return_quantity,
        'catalog'
    FROM catalog_returns
    UNION ALL
    SELECT
        wr_returned_date_sk,
        wr_item_sk,
        wr_return_amt,
        wr_net_loss,
        wr_return_quantity,
        'web'
    FROM web_returns
),
sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        s.channel,
        sum(s.net_paid) AS total_sales,
        sum(s.net_profit) AS total_profit,
        sum(s.quantity) AS total_quantity,
        count(*) AS sales_transactions
    FROM sales s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, s.channel
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        r.channel,
        sum(r.return_amount) AS total_returns,
        sum(r.net_loss) AS total_return_loss,
        sum(r.quantity) AS total_return_quantity,
        count(*) AS return_transactions
    FROM returns r
    JOIN date_dim d ON r.returned_date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, r.channel
),
combined AS (
    SELECT
        sa.d_year,
        sa.d_month_seq,
        sa.i_category,
        sa.i_class,
        sa.channel,
        sa.total_sales,
        sa.total_profit,
        sa.total_quantity,
        coalesce(ra.total_returns, 0) AS total_returns,
        coalesce(ra.total_return_loss, 0) AS total_return_loss,
        coalesce(ra.total_return_quantity, 0) AS total_return_quantity,
        (sa.total_sales - coalesce(ra.total_returns, 0)) AS net_sales,
        (sa.total_profit - coalesce(ra.total_return_loss, 0)) AS net_profit_adj,
        row_number() OVER (PARTITION BY sa.d_year, sa.d_month_seq, sa.channel ORDER BY (sa.total_sales - coalesce(ra.total_returns, 0)) DESC) AS sales_rank,
        lag((sa.total_sales - coalesce(ra.total_returns, 0))) OVER (PARTITION BY sa.channel ORDER BY sa.d_year, sa.d_month_seq) AS prev_month_net_sales,
        round(((sa.total_sales - coalesce(ra.total_returns, 0)) - lag((sa.total_sales - coalesce(ra.total_returns, 0))) OVER (PARTITION BY sa.channel ORDER BY sa.d_year, sa.d_month_seq)) * 100.0 / nullif(lag((sa.total_sales - coalesce(ra.total_returns, 0))) OVER (PARTITION BY sa.channel ORDER BY sa.d_year, sa.d_month_seq), 0), 2) AS mom_growth_pct
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
      ON sa.d_year = ra.d_year
     AND sa.d_month_seq = ra.d_month_seq
     AND sa.i_category = ra.i_category
     AND sa.i_class = ra.i_class
     AND sa.channel = ra.channel
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    i_class,
    channel,
    total_sales,
    total_profit,
    total_quantity,
    total_returns,
    total_return_loss,
    net_sales,
    net_profit_adj,
    sales_rank,
    mom_growth_pct
FROM combined
WHERE sales_rank <= 5
ORDER BY d_year, d_month_seq, channel, sales_rank

WITH
sales AS (
    SELECT 'store' AS channel,
           ss.ss_sold_date_sk AS sales_date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    UNION ALL
    SELECT 'catalog' AS channel,
           cs.cs_sold_date_sk AS sales_date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT 'web' AS channel,
           ws.ws_sold_date_sk AS sales_date_sk,
           ws.ws_item_sk AS item_sk,
           ws.ws_quantity AS quantity,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
),
returns AS (
    SELECT 'store' AS channel,
           sr.sr_returned_date_sk AS return_date_sk,
           sr.sr_item_sk AS item_sk,
           sr.sr_return_quantity AS quantity,
           sr.sr_net_loss AS net_loss
    FROM store_returns sr
    UNION ALL
    SELECT 'catalog' AS channel,
           cr.cr_returned_date_sk AS return_date_sk,
           cr.cr_item_sk AS item_sk,
           cr.cr_return_quantity AS quantity,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    UNION ALL
    SELECT 'web' AS channel,
           wr.wr_returned_date_sk AS return_date_sk,
           wr.wr_item_sk AS item_sk,
           wr.wr_return_quantity AS quantity,
           wr.wr_net_loss AS net_loss
    FROM web_returns wr
),
sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_moy AS month,
        s.channel,
        i.i_category,
        i.i_class,
        SUM(s.quantity) AS total_quantity_sold,
        SUM(s.net_paid) AS total_net_paid,
        SUM(s.net_profit) AS total_net_profit
    FROM sales s
    JOIN date_dim d ON s.sales_date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    GROUP BY
        d.d_year,
        d.d_month_seq,
        d.d_moy,
        s.channel,
        i.i_category,
        i.i_class
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_moy AS month,
        r.channel,
        i.i_category,
        i.i_class,
        SUM(r.quantity) AS total_quantity_returned,
        SUM(r.net_loss) AS total_net_loss
    FROM returns r
    JOIN date_dim d ON r.return_date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    GROUP BY
        d.d_year,
        d.d_month_seq,
        d.d_moy,
        r.channel,
        i.i_category,
        i.i_class
),
combined AS (
    SELECT
        COALESCE(sa.d_year, ra.d_year) AS d_year,
        COALESCE(sa.d_month_seq, ra.d_month_seq) AS d_month_seq,
        COALESCE(sa.month, ra.month) AS month,
        COALESCE(sa.channel, ra.channel) AS channel,
        COALESCE(sa.i_category, ra.i_category) AS i_category,
        COALESCE(sa.i_class, ra.i_class) AS i_class,
        COALESCE(sa.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(sa.total_net_paid, 0) AS total_net_paid,
        COALESCE(sa.total_net_profit, 0) AS total_net_profit,
        COALESCE(ra.total_quantity_returned, 0) AS total_quantity_returned,
        COALESCE(ra.total_net_loss, 0) AS total_net_loss,
        (COALESCE(sa.total_net_profit, 0) - COALESCE(ra.total_net_loss, 0)) AS net_profit_adjusted
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra
        ON sa.d_year = ra.d_year
       AND sa.d_month_seq = ra.d_month_seq
       AND sa.channel = ra.channel
       AND sa.i_category = ra.i_category
       AND sa.i_class = ra.i_class
),
final AS (
    SELECT
        d_year,
        d_month_seq,
        month,
        channel,
        i_category,
        i_class,
        total_quantity_sold,
        total_quantity_returned,
        total_net_paid,
        total_net_profit,
        total_net_loss,
        net_profit_adjusted,
        net_profit_adjusted / NULLIF(total_net_paid + total_net_loss, 0) AS profit_margin,
        SUM(net_profit_adjusted) OVER (PARTITION BY channel, i_category ORDER BY d_year, d_month_seq) AS cumulative_profit,
        LAG(net_profit_adjusted) OVER (PARTITION BY channel, i_category ORDER BY d_year, d_month_seq) AS prev_month_profit,
        net_profit_adjusted - LAG(net_profit_adjusted) OVER (PARTITION BY channel, i_category ORDER BY d_year, d_month_seq) AS month_over_month_change,
        RANK() OVER (PARTITION BY d_year, d_month_seq, channel ORDER BY net_profit_adjusted DESC) AS category_rank_in_month
    FROM combined
)
SELECT
    d_year,
    d_month_seq,
    month,
    channel,
    i_category,
    i_class,
    total_quantity_sold,
    total_quantity_returned,
    total_net_paid,
    total_net_profit,
    total_net_loss,
    net_profit_adjusted,
    profit_margin,
    cumulative_profit,
    prev_month_profit,
    month_over_month_change,
    category_rank_in_month
FROM final
WHERE category_rank_in_month <= 5
ORDER BY d_year, d_month_seq, channel, category_rank_in_month

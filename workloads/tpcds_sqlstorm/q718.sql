WITH sales AS (
    SELECT
        'catalog' AS channel,
        cs_sold_date_sk AS sold_date_sk,
        cs_ext_sales_price AS ext_sales_price,
        cs_ext_discount_amt AS discount_amt,
        cs_quantity AS quantity,
        cs_net_profit AS net_profit,
        cs_item_sk AS item_sk,
        cs_promo_sk AS promo_sk
    FROM catalog_sales
    UNION ALL
    SELECT
        'store' AS channel,
        ss_sold_date_sk,
        ss_ext_sales_price,
        ss_ext_discount_amt,
        ss_quantity,
        ss_net_profit,
        ss_item_sk,
        ss_promo_sk
    FROM store_sales
    UNION ALL
    SELECT
        'web' AS channel,
        ws_sold_date_sk,
        ws_ext_sales_price,
        ws_ext_discount_amt,
        ws_quantity,
        ws_net_profit,
        ws_item_sk,
        ws_promo_sk
    FROM web_sales
),
returns AS (
    SELECT
        'catalog' AS channel,
        cr_returned_date_sk AS returned_date_sk,
        cr_net_loss AS net_loss,
        cr_return_quantity AS quantity,
        cr_item_sk AS item_sk,
        cr_reason_sk AS reason_sk
    FROM catalog_returns
    UNION ALL
    SELECT
        'store' AS channel,
        sr_returned_date_sk,
        sr_net_loss,
        sr_return_quantity,
        sr_item_sk,
        sr_reason_sk
    FROM store_returns
    UNION ALL
    SELECT
        'web' AS channel,
        wr_returned_date_sk,
        wr_net_loss,
        wr_return_quantity,
        wr_item_sk,
        wr_reason_sk
    FROM web_returns
),
sales_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        d.d_quarter_name,
        i.i_category,
        i.i_class,
        s.channel,
        COALESCE(p.p_promo_sk, -1) AS promo_sk,
        COALESCE(p.p_promo_id, 'NO_PROMO') AS promo_id,
        SUM(s.ext_sales_price) AS total_sales,
        SUM(s.discount_amt) AS total_discount,
        SUM(s.net_profit) AS total_profit,
        SUM(s.quantity) AS total_quantity,
        COUNT(*) AS transaction_count,
        SUM(CASE WHEN p.p_channel_dmail = 'Y' THEN 1 ELSE 0 END) AS promo_dmail_count,
        SUM(CASE WHEN p.p_channel_email = 'Y' THEN 1 ELSE 0 END) AS promo_email_count,
        SUM(CASE WHEN p.p_channel_catalog = 'Y' THEN 1 ELSE 0 END) AS promo_catalog_count,
        SUM(CASE WHEN p.p_channel_tv = 'Y' THEN 1 ELSE 0 END) AS promo_tv_count,
        SUM(CASE WHEN p.p_channel_radio = 'Y' THEN 1 ELSE 0 END) AS promo_radio_count,
        SUM(CASE WHEN p.p_channel_press = 'Y' THEN 1 ELSE 0 END) AS promo_press_count,
        SUM(CASE WHEN p.p_channel_event = 'Y' THEN 1 ELSE 0 END) AS promo_event_count,
        SUM(CASE WHEN p.p_channel_demo = 'Y' THEN 1 ELSE 0 END) AS promo_demo_count
    FROM sales s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON s.promo_sk = p.p_promo_sk
    GROUP BY
        d.d_year,
        d.d_quarter_seq,
        d.d_quarter_name,
        i.i_category,
        i.i_class,
        s.channel,
        COALESCE(p.p_promo_sk, -1),
        COALESCE(p.p_promo_id, 'NO_PROMO')
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        d.d_quarter_name,
        i.i_category,
        i.i_class,
        r.channel,
        SUM(r.net_loss) AS total_return_loss,
        SUM(r.quantity) AS total_return_quantity
    FROM returns r
    JOIN date_dim d ON r.returned_date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    GROUP BY
        d.d_year,
        d.d_quarter_seq,
        d.d_quarter_name,
        i.i_category,
        i.i_class,
        r.channel
),
combined AS (
    SELECT
        sa.d_year,
        sa.d_quarter_seq,
        sa.d_quarter_name,
        sa.i_category,
        sa.i_class,
        sa.channel,
        sa.promo_id,
        sa.total_sales,
        sa.total_discount,
        sa.total_profit,
        sa.total_quantity,
        sa.transaction_count,
        COALESCE(ra.total_return_loss, 0) AS total_return_loss,
        COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
        sa.promo_dmail_count,
        sa.promo_email_count,
        sa.promo_catalog_count,
        sa.promo_tv_count,
        sa.promo_radio_count,
        sa.promo_press_count,
        sa.promo_event_count,
        sa.promo_demo_count
    FROM sales_agg sa
    LEFT JOIN returns_agg ra ON
        sa.d_year = ra.d_year AND
        sa.d_quarter_seq = ra.d_quarter_seq AND
        sa.d_quarter_name = ra.d_quarter_name AND
        sa.i_category = ra.i_category AND
        sa.i_class = ra.i_class AND
        sa.channel = ra.channel
)
SELECT
    d_year,
    d_quarter_name,
    d_quarter_seq,
    i_category,
    i_class,
    channel,
    promo_id,
    total_sales,
    total_discount,
    total_profit,
    total_quantity,
    transaction_count,
    total_return_loss,
    total_return_quantity,
    CASE WHEN total_sales <> 0 THEN total_discount / total_sales ELSE NULL END AS discount_rate,
    CASE WHEN total_sales <> 0 THEN total_profit / total_sales ELSE NULL END AS profit_margin,
    SUM(total_profit) OVER (
        PARTITION BY channel, d_year
        ORDER BY d_quarter_seq
        ROWS UNBOUNDED PRECEDING
    ) AS ytd_profit,
    DENSE_RANK() OVER (
        PARTITION BY channel, d_year
        ORDER BY total_profit DESC
    ) AS profit_rank,
    promo_dmail_count,
    promo_email_count,
    promo_catalog_count,
    promo_tv_count,
    promo_radio_count,
    promo_press_count,
    promo_event_count,
    promo_demo_count
FROM combined
WHERE total_sales > 0
ORDER BY d_year, d_quarter_seq, channel, profit_rank
LIMIT 100

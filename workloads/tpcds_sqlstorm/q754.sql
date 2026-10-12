WITH sales_union AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_order_number AS order_number,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_ext_tax AS ext_tax,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_promo_sk AS promo_sk,
        'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_tax,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_promo_sk,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_tax,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_promo_sk,
        'web' AS channel
    FROM web_sales ws
),
returns_union AS (
    SELECT
        cr.cr_returned_date_sk AS returned_date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_order_number AS order_number,
        cr.cr_return_quantity AS quantity,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_tax AS return_tax,
        cr.cr_net_loss AS net_loss,
        'catalog' AS channel
    FROM catalog_returns cr
    UNION ALL
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_net_loss,
        'store' AS channel
    FROM store_returns sr
    UNION ALL
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_order_number,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_net_loss,
        'web' AS channel
    FROM web_returns wr
),
sales_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        i.i_brand,
        s.channel,
        SUM(s.ext_sales_price) AS total_sales,
        SUM(s.ext_tax) AS total_tax,
        SUM(s.net_paid) AS total_net_paid,
        SUM(s.net_profit) AS total_profit,
        COUNT(DISTINCT s.order_number) AS distinct_orders,
        COUNT(*) AS total_transactions
    FROM sales_union s
    JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    GROUP BY
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        i.i_brand,
        s.channel
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        i.i_brand,
        r.channel,
        SUM(r.return_amount) AS total_returns,
        SUM(r.return_tax) AS total_return_tax,
        SUM(r.net_loss) AS total_return_loss,
        COUNT(DISTINCT r.order_number) AS distinct_return_orders,
        COUNT(*) AS total_return_transactions
    FROM returns_union r
    JOIN date_dim d ON r.returned_date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    GROUP BY
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        i.i_brand,
        r.channel
),
combined AS (
    SELECT
        s.d_year,
        s.d_quarter_seq,
        s.i_category,
        s.i_brand,
        s.channel,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        s.total_sales - COALESCE(r.total_returns, 0) AS net_sales,
        s.total_profit,
        s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit,
        s.total_tax,
        s.total_tax - COALESCE(r.total_return_tax, 0) AS net_tax,
        s.distinct_orders,
        COALESCE(r.distinct_return_orders, 0) AS distinct_return_orders,
        s.total_transactions,
        COALESCE(r.total_return_transactions, 0) AS total_return_transactions
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.d_year = r.d_year
        AND s.d_quarter_seq = r.d_quarter_seq
        AND s.i_category = r.i_category
        AND s.i_brand = r.i_brand
        AND s.channel = r.channel
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year, channel ORDER BY net_sales DESC) AS rn
    FROM combined
)
SELECT
    d_year,
    channel,
    i_category,
    i_brand,
    total_sales,
    total_returns,
    net_sales,
    total_profit,
    net_profit,
    total_tax,
    net_tax,
    distinct_orders,
    distinct_return_orders,
    total_transactions,
    total_return_transactions
FROM ranked
WHERE rn <= 10
ORDER BY d_year, channel, net_sales DESC

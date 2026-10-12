WITH sales_data AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amt,
        'catalog' AS channel,
        CAST(NULL AS varchar) AS state
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        'store',
        s.s_state
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        'web',
        CAST(NULL AS varchar)
    FROM web_sales ws
),
returns_data AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_return_quantity AS quantity,
        cr.cr_net_loss AS net_loss,
        'catalog' AS channel,
        CAST(NULL AS varchar) AS state
    FROM catalog_returns cr
    UNION ALL
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        'store',
        s.s_state
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    UNION ALL
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        'web',
        CAST(NULL AS varchar)
    FROM web_returns wr
),
sales_agg AS (
    SELECT
        d.d_year,
        sd.channel,
        COALESCE(sd.state, 'UNKNOWN') AS state,
        i.i_category,
        SUM(sd.quantity) AS total_quantity,
        SUM(sd.net_profit) AS total_net_profit,
        SUM(sd.discount_amt) AS total_discount
    FROM sales_data sd
    JOIN date_dim d ON sd.date_sk = d.d_date_sk
    JOIN item i ON sd.item_sk = i.i_item_sk
    GROUP BY
        d.d_year,
        sd.channel,
        COALESCE(sd.state, 'UNKNOWN'),
        i.i_category
),
returns_agg AS (
    SELECT
        d.d_year,
        rd.channel,
        COALESCE(rd.state, 'UNKNOWN') AS state,
        i.i_category,
        SUM(rd.quantity) AS total_return_quantity,
        SUM(rd.net_loss) AS total_net_loss
    FROM returns_data rd
    JOIN date_dim d ON rd.date_sk = d.d_date_sk
    JOIN item i ON rd.item_sk = i.i_item_sk
    GROUP BY
        d.d_year,
        rd.channel,
        COALESCE(rd.state, 'UNKNOWN'),
        i.i_category
),
combined AS (
    SELECT
        COALESCE(sa.d_year, ra.d_year) AS year,
        COALESCE(sa.channel, ra.channel) AS channel,
        COALESCE(sa.state, ra.state) AS state,
        COALESCE(sa.i_category, ra.i_category) AS category,
        COALESCE(sa.total_quantity, 0) AS total_quantity,
        COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(sa.total_net_profit, 0) AS total_net_profit,
        COALESCE(ra.total_net_loss, 0) AS total_net_loss,
        COALESCE(sa.total_discount, 0) AS total_discount,
        (COALESCE(sa.total_net_profit, 0) - COALESCE(ra.total_net_loss, 0)) AS net_gain,
        CASE WHEN COALESCE(sa.total_quantity, 0) = 0 THEN NULL
             ELSE COALESCE(ra.total_return_quantity, 0) / CAST(NULLIF(COALESCE(sa.total_quantity, 0), 0) AS double)
        END AS return_rate,
        CASE WHEN COALESCE(sa.total_quantity, 0) = 0 THEN NULL
             ELSE COALESCE(sa.total_discount, 0) / CAST(NULLIF(COALESCE(sa.total_quantity, 0), 0) AS double)
        END AS avg_discount_per_item
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra
        ON sa.d_year = ra.d_year
       AND sa.channel = ra.channel
       AND sa.state = ra.state
       AND sa.i_category = ra.i_category
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY year ORDER BY net_gain DESC) AS rn
    FROM combined
)
SELECT
    year,
    channel,
    state,
    category,
    total_quantity,
    total_return_quantity,
    total_net_profit,
    total_net_loss,
    total_discount,
    net_gain,
    return_rate,
    avg_discount_per_item
FROM ranked
WHERE rn <= 5
ORDER BY year DESC, net_gain DESC

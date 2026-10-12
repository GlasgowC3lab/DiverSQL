WITH sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category,
        'catalog' AS channel,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category

    UNION ALL

    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category,
        'store' AS channel,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category

    UNION ALL

    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category,
        'web' AS channel,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category
),

returns_agg AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category,
        'catalog' AS channel,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category

    UNION ALL

    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category,
        'store' AS channel,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category

    UNION ALL

    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category,
        'web' AS channel,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_moy, i.i_category
),

combined AS (
    SELECT
        s.year,
        s.month,
        s.i_category,
        s.channel,
        s.total_net_paid,
        s.total_net_profit,
        s.total_discount,
        s.order_cnt,
        s.total_quantity,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        COALESCE(r.total_return_qty, 0) AS total_return_qty,
        s.total_net_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
        CASE WHEN s.total_net_paid > 0 THEN (s.total_net_profit - COALESCE(r.total_return_loss, 0)) / s.total_net_paid ELSE NULL END AS profit_margin,
        CASE WHEN s.total_quantity > 0 THEN s.total_discount / s.total_quantity ELSE NULL END AS avg_discount_per_item
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.year = r.year
        AND s.month = r.month
        AND s.i_category = r.i_category
        AND s.channel = r.channel
),

ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY year, month, channel ORDER BY net_profit_after_returns DESC) AS profit_rank
    FROM combined
)

SELECT
    year,
    month,
    i_category,
    channel,
    total_net_paid,
    net_profit_after_returns,
    profit_margin,
    avg_discount_per_item,
    total_return_qty,
    profit_rank
FROM ranked
WHERE profit_rank <= 10
ORDER BY year, month, channel, profit_rank

WITH
sales_catalog AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(cs.cs_net_profit) AS sales_net_profit,
        SUM(cs.cs_ext_sales_price) AS sales_total,
        SUM(cs.cs_quantity) AS sales_qty,
        COUNT(*) AS sales_orders,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, i.i_category
),
returns_catalog AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(cr.cr_net_loss) AS return_net_loss,
        SUM(cr.cr_return_amount) AS return_amount,
        SUM(cr.cr_return_quantity) AS return_qty,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, i.i_category
),
sales_store AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(ss.ss_net_profit) AS sales_net_profit,
        SUM(ss.ss_ext_sales_price) AS sales_total,
        SUM(ss.ss_quantity) AS sales_qty,
        COUNT(*) AS sales_orders,
        AVG(ss.ss_ext_discount_amt) AS avg_discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, i.i_category
),
returns_store AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(sr.sr_net_loss) AS return_net_loss,
        SUM(sr.sr_return_amt) AS return_amount,
        SUM(sr.sr_return_quantity) AS return_qty,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, i.i_category
),
sales_web AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(ws.ws_net_profit) AS sales_net_profit,
        SUM(ws.ws_ext_sales_price) AS sales_total,
        SUM(ws.ws_quantity) AS sales_qty,
        COUNT(*) AS sales_orders,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, i.i_category
),
returns_web AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(wr.wr_net_loss) AS return_net_loss,
        SUM(wr.wr_return_amt) AS return_amount,
        SUM(wr.wr_return_quantity) AS return_qty,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, i.i_category
),
combined AS (
    SELECT
        s.d_year,
        s.i_category,
        'catalog' AS channel,
        s.sales_net_profit,
        s.sales_total,
        s.sales_qty,
        s.sales_orders,
        s.avg_discount,
        COALESCE(r.return_net_loss, 0) AS return_net_loss,
        COALESCE(r.return_amount, 0) AS return_amount,
        COALESCE(r.return_qty, 0) AS return_qty,
        COALESCE(r.return_count, 0) AS return_count,
        s.sales_net_profit - COALESCE(r.return_net_loss, 0) AS net_profit_after_returns
    FROM sales_catalog s
    LEFT JOIN returns_catalog r
        ON s.d_year = r.d_year AND s.i_category = r.i_category
    UNION ALL
    SELECT
        s.d_year,
        s.i_category,
        'store' AS channel,
        s.sales_net_profit,
        s.sales_total,
        s.sales_qty,
        s.sales_orders,
        s.avg_discount,
        COALESCE(r.return_net_loss, 0),
        COALESCE(r.return_amount, 0),
        COALESCE(r.return_qty, 0),
        COALESCE(r.return_count, 0),
        s.sales_net_profit - COALESCE(r.return_net_loss, 0)
    FROM sales_store s
    LEFT JOIN returns_store r
        ON s.d_year = r.d_year AND s.i_category = r.i_category
    UNION ALL
    SELECT
        s.d_year,
        s.i_category,
        'web' AS channel,
        s.sales_net_profit,
        s.sales_total,
        s.sales_qty,
        s.sales_orders,
        s.avg_discount,
        COALESCE(r.return_net_loss, 0),
        COALESCE(r.return_amount, 0),
        COALESCE(r.return_qty, 0),
        COALESCE(r.return_count, 0),
        s.sales_net_profit - COALESCE(r.return_net_loss, 0)
    FROM sales_web s
    LEFT JOIN returns_web r
        ON s.d_year = r.d_year AND s.i_category = r.i_category
),
ranked AS (
    SELECT
        d_year,
        i_category,
        channel,
        sales_net_profit,
        sales_total,
        sales_qty,
        sales_orders,
        avg_discount,
        return_net_loss,
        return_amount,
        return_qty,
        return_count,
        net_profit_after_returns,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY net_profit_after_returns DESC) AS rank_by_profit
    FROM combined
)
SELECT
    d_year,
    i_category,
    channel,
    sales_net_profit,
    sales_total,
    sales_qty,
    sales_orders,
    avg_discount,
    return_net_loss,
    return_amount,
    return_qty,
    return_count,
    net_profit_after_returns
FROM ranked
WHERE rank_by_profit <= 5
ORDER BY d_year, net_profit_after_returns DESC, channel

WITH catalog_sales_2001 AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        i.i_category,
        i.i_class,
        i.i_brand,
        'Catalog' AS channel,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_ext_discount_amt AS discount_amount,
        cs.cs_ext_tax AS tax_amount,
        cs.cs_net_profit AS net_profit,
        cs.cs_order_number AS order_number,
        cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
), store_sales_2001 AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        i.i_category,
        i.i_class,
        i.i_brand,
        'Store' AS channel,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_ext_discount_amt AS discount_amount,
        ss.ss_ext_tax AS tax_amount,
        ss.ss_net_profit AS net_profit,
        ss.ss_ticket_number AS order_number,
        ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
), web_sales_2001 AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        i.i_category,
        i.i_class,
        i.i_brand,
        'Web' AS channel,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_ext_discount_amt AS discount_amount,
        ws.ws_ext_tax AS tax_amount,
        ws.ws_net_profit AS net_profit,
        ws.ws_order_number AS order_number,
        ws.ws_item_sk AS item_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
), all_sales AS (
    SELECT * FROM catalog_sales_2001
    UNION ALL
    SELECT * FROM store_sales_2001
    UNION ALL
    SELECT * FROM web_sales_2001
), catalog_returns_2001 AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        i.i_category,
        i.i_class,
        i.i_brand,
        'Catalog' AS channel,
        cr.cr_return_quantity AS return_qty,
        cr.cr_net_loss AS net_loss,
        cr.cr_order_number AS order_number,
        cr.cr_item_sk AS item_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
), store_returns_2001 AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        i.i_category,
        i.i_class,
        i.i_brand,
        'Store' AS channel,
        sr.sr_return_quantity AS return_qty,
        sr.sr_net_loss AS net_loss,
        sr.sr_ticket_number AS order_number,
        sr.sr_item_sk AS item_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
), web_returns_2001 AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month,
        i.i_category,
        i.i_class,
        i.i_brand,
        'Web' AS channel,
        wr.wr_return_quantity AS return_qty,
        wr.wr_net_loss AS net_loss,
        wr.wr_order_number AS order_number,
        wr.wr_item_sk AS item_sk
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
), all_returns AS (
    SELECT * FROM catalog_returns_2001
    UNION ALL
    SELECT * FROM store_returns_2001
    UNION ALL
    SELECT * FROM web_returns_2001
), aggregated AS (
    SELECT
        s.d_year,
        s.month,
        s.i_category,
        s.i_class,
        s.i_brand,
        s.channel,
        COUNT(DISTINCT s.order_number) AS distinct_orders,
        SUM(s.sales_amount) AS total_sales,
        SUM(s.discount_amount) AS total_discount,
        SUM(s.tax_amount) AS total_tax,
        SUM(s.net_profit) AS total_net_profit,
        COALESCE(SUM(r.net_loss), 0) AS total_return_loss,
        SUM(s.net_profit) - COALESCE(SUM(r.net_loss), 0) AS net_profit_after_returns,
        CASE WHEN SUM(s.sales_amount) = 0 THEN 0 ELSE SUM(s.discount_amount) / SUM(s.sales_amount) END AS discount_rate,
        CASE WHEN SUM(s.sales_amount) = 0 THEN 0 ELSE SUM(s.net_profit) / SUM(s.sales_amount) END AS profit_margin
    FROM all_sales s
    LEFT JOIN all_returns r
        ON s.channel = r.channel
        AND s.order_number = r.order_number
        AND s.item_sk = r.item_sk
    GROUP BY s.d_year, s.month, s.i_category, s.i_class, s.i_brand, s.channel
)
SELECT
    d_year,
    month,
    i_category,
    i_class,
    i_brand,
    channel,
    distinct_orders,
    total_sales,
    total_discount,
    total_tax,
    total_net_profit,
    total_return_loss,
    net_profit_after_returns,
    discount_rate,
    profit_margin,
    SUM(total_sales) OVER (PARTITION BY d_year, month) AS sales_all_channels,
    SUM(total_net_profit) OVER (PARTITION BY d_year, month) AS profit_all_channels,
    SUM(total_sales) OVER (PARTITION BY d_year ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ytd_sales,
    SUM(net_profit_after_returns) OVER (PARTITION BY d_year ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ytd_profit_after_returns,
    RANK() OVER (PARTITION BY d_year, month ORDER BY net_profit_after_returns DESC) AS profit_rank
FROM aggregated
ORDER BY d_year, month, net_profit_after_returns DESC
LIMIT 200

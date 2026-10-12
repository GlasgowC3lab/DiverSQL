WITH
    date_month AS (
        SELECT d_date_sk, d_year, d_moy AS d_month
        FROM date_dim
        WHERE d_year BETWEEN 2000 AND 2002
    ),
    sales_all AS (
        SELECT
            i.i_item_sk,
            i.i_category,
            i.i_class,
            d.d_year,
            d.d_month,
            SUM(cs.cs_quantity) AS quantity,
            SUM(cs.cs_ext_sales_price) AS sales,
            SUM(cs.cs_ext_discount_amt) AS discount,
            SUM(cs.cs_net_profit) AS profit
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN date_month d ON cs.cs_sold_date_sk = d.d_date_sk
        GROUP BY i.i_item_sk, i.i_category, i.i_class, d.d_year, d.d_month
        UNION ALL
        SELECT
            i.i_item_sk,
            i.i_category,
            i.i_class,
            d.d_year,
            d.d_month,
            SUM(ss.ss_quantity) AS quantity,
            SUM(ss.ss_ext_sales_price) AS sales,
            SUM(ss.ss_ext_discount_amt) AS discount,
            SUM(ss.ss_net_profit) AS profit
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN date_month d ON ss.ss_sold_date_sk = d.d_date_sk
        GROUP BY i.i_item_sk, i.i_category, i.i_class, d.d_year, d.d_month
        UNION ALL
        SELECT
            i.i_item_sk,
            i.i_category,
            i.i_class,
            d.d_year,
            d.d_month,
            SUM(ws.ws_quantity) AS quantity,
            SUM(ws.ws_ext_sales_price) AS sales,
            SUM(ws.ws_ext_discount_amt) AS discount,
            SUM(ws.ws_net_profit) AS profit
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN date_month d ON ws.ws_sold_date_sk = d.d_date_sk
        GROUP BY i.i_item_sk, i.i_category, i.i_class, d.d_year, d.d_month
    ),
    returns_all AS (
        SELECT
            cr.cr_item_sk AS i_item_sk,
            d.d_year,
            d.d_month,
            SUM(cr.cr_return_quantity) AS return_qty,
            SUM(cr.cr_return_amt_inc_tax) AS return_amount
        FROM catalog_returns cr
        JOIN date_month d ON cr.cr_returned_date_sk = d.d_date_sk
        GROUP BY cr.cr_item_sk, d.d_year, d.d_month
        UNION ALL
        SELECT
            sr.sr_item_sk AS i_item_sk,
            d.d_year,
            d.d_month,
            SUM(sr.sr_return_quantity) AS return_qty,
            SUM(sr.sr_return_amt_inc_tax) AS return_amount
        FROM store_returns sr
        JOIN date_month d ON sr.sr_returned_date_sk = d.d_date_sk
        GROUP BY sr.sr_item_sk, d.d_year, d.d_month
        UNION ALL
        SELECT
            wr.wr_item_sk AS i_item_sk,
            d.d_year,
            d.d_month,
            SUM(wr.wr_return_quantity) AS return_qty,
            SUM(wr.wr_return_amt_inc_tax) AS return_amount
        FROM web_returns wr
        JOIN date_month d ON wr.wr_returned_date_sk = d.d_date_sk
        GROUP BY wr.wr_item_sk, d.d_year, d.d_month
    ),
    merged AS (
        SELECT
            s.i_item_sk,
            s.i_category,
            s.i_class,
            s.d_year,
            s.d_month,
            s.quantity,
            s.sales,
            s.discount,
            s.profit,
            COALESCE(r.return_qty, 0) AS return_qty,
            COALESCE(r.return_amount, 0) AS return_amount,
            s.profit - COALESCE(r.return_amount, 0) AS net_profit,
            s.sales - s.discount AS net_sales,
            (s.profit - COALESCE(r.return_amount, 0)) / NULLIF(s.sales, 0) AS profit_margin
        FROM sales_all s
        LEFT JOIN returns_all r
            ON s.i_item_sk = r.i_item_sk
            AND s.d_year = r.d_year
            AND s.d_month = r.d_month
    ),
    category_monthly AS (
        SELECT
            i_category,
            i_class,
            d_year,
            d_month,
            SUM(quantity) AS total_quantity,
            SUM(sales) AS total_sales,
            SUM(discount) AS total_discount,
            SUM(profit) AS total_profit,
            SUM(return_qty) AS total_return_qty,
            SUM(return_amount) AS total_return_amount,
            SUM(net_profit) AS total_net_profit,
            SUM(net_sales) AS total_net_sales,
            SUM(net_profit) / NULLIF(SUM(sales), 0) AS profit_margin
        FROM merged
        GROUP BY i_category, i_class, d_year, d_month
    )
SELECT
    i_category,
    i_class,
    d_year,
    d_month,
    total_quantity,
    total_sales,
    total_discount,
    total_profit,
    total_return_qty,
    total_return_amount,
    total_net_profit,
    total_net_sales,
    profit_margin,
    ROW_NUMBER() OVER (PARTITION BY i_category, i_class ORDER BY total_net_profit DESC) AS profit_rank,
    AVG(total_net_profit) OVER (PARTITION BY i_category, i_class ORDER BY d_year, d_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS profit_moving_avg_3mo
FROM category_monthly
ORDER BY i_category, i_class, d_year, d_month
LIMIT 200

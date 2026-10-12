WITH
sales AS (
    SELECT
        'Catalog' AS channel,
        d.d_year AS year,
        d.d_quarter_seq AS quarter,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS sales,
        cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
    UNION ALL
    SELECT
        'Store' AS channel,
        d.d_year,
        d.d_quarter_seq,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
    UNION ALL
    SELECT
        'Web' AS channel,
        d.d_year,
        d.d_quarter_seq,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
),
returns AS (
    SELECT
        'Catalog' AS channel,
        d.d_year AS year,
        d.d_quarter_seq AS quarter,
        cr.cr_item_sk AS item_sk,
        cr.cr_refunded_customer_sk AS customer_sk,
        cr.cr_return_quantity AS quantity,
        cr.cr_return_amount AS returns,
        cr.cr_net_loss AS loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
    UNION ALL
    SELECT
        'Store' AS channel,
        d.d_year,
        d.d_quarter_seq,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
    UNION ALL
    SELECT
        'Web' AS channel,
        d.d_year,
        d.d_quarter_seq,
        wr.wr_item_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
),
agg_sales AS (
    SELECT
        channel,
        year,
        quarter,
        SUM(sales) AS total_sales,
        SUM(profit) AS total_profit,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT item_sk) AS distinct_items,
        COUNT(DISTINCT customer_sk) AS distinct_customers
    FROM sales
    GROUP BY channel, year, quarter
),
agg_returns AS (
    SELECT
        channel,
        year,
        quarter,
        SUM(returns) AS total_returns,
        SUM(loss) AS total_loss,
        SUM(quantity) AS total_return_qty,
        COUNT(DISTINCT item_sk) AS distinct_items_returned,
        COUNT(DISTINCT customer_sk) AS distinct_customers_returned
    FROM returns
    GROUP BY channel, year, quarter
),
sales_items AS (
    SELECT
        channel,
        year,
        quarter,
        item_sk,
        SUM(sales) AS item_sales,
        SUM(quantity) AS item_qty
    FROM sales
    GROUP BY channel, year, quarter, item_sk
),
sales_customers AS (
    SELECT
        channel,
        year,
        quarter,
        customer_sk,
        SUM(sales) AS customer_sales,
        SUM(quantity) AS customer_qty
    FROM sales
    GROUP BY channel, year, quarter, customer_sk
),
top_items AS (
    SELECT
        channel,
        year,
        quarter,
        slice(array_agg(item_sk ORDER BY item_sales DESC), 1, 5) AS top_5_item_sk
    FROM sales_items
    GROUP BY channel, year, quarter
),
top_customers AS (
    SELECT
        channel,
        year,
        quarter,
        slice(array_agg(customer_sk ORDER BY customer_sales DESC), 1, 5) AS top_5_customer_sk
    FROM sales_customers
    GROUP BY channel, year, quarter
)
SELECT
    a.channel,
    a.year,
    a.quarter,
    a.total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    a.total_sales - COALESCE(r.total_returns, 0) AS net_sales,
    a.total_profit,
    a.total_profit / NULLIF(a.total_sales, 0) AS profit_margin,
    a.total_quantity,
    COALESCE(r.total_return_qty, 0) AS total_return_quantity,
    LAG(a.total_sales) OVER (PARTITION BY a.channel ORDER BY a.year, a.quarter) AS prev_total_sales,
    (a.total_sales - LAG(a.total_sales) OVER (PARTITION BY a.channel ORDER BY a.year, a.quarter))
      / NULLIF(LAG(a.total_sales) OVER (PARTITION BY a.channel ORDER BY a.year, a.quarter), 0) AS sales_qoq_growth,
    ti.top_5_item_sk,
    tc.top_5_customer_sk
FROM agg_sales a
LEFT JOIN agg_returns r
    ON a.channel = r.channel AND a.year = r.year AND a.quarter = r.quarter
LEFT JOIN top_items ti
    ON a.channel = ti.channel AND a.year = ti.year AND a.quarter = ti.quarter
LEFT JOIN top_customers tc
    ON a.channel = tc.channel AND a.year = tc.year AND a.quarter = tc.quarter
ORDER BY a.channel, a.year, a.quarter

WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        i.i_class,
        'catalog' AS channel,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        COUNT(*) AS order_count
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class
),
store_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        i.i_class,
        'store' AS channel,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        COUNT(*) AS order_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class
),
web_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        i.i_class,
        'web' AS channel,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        COUNT(*) AS order_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        i.i_class,
        'catalog' AS channel,
        SUM(cr.cr_return_quantity) AS return_quantity,
        SUM(cr.cr_return_amount) AS return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        i.i_class,
        'store' AS channel,
        SUM(sr.sr_return_quantity) AS return_quantity,
        SUM(sr.sr_return_amt) AS return_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class
    UNION ALL
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        i.i_class,
        'web' AS channel,
        SUM(wr.wr_return_quantity) AS return_quantity,
        SUM(wr.wr_return_amt) AS return_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class
),
combined AS (
    SELECT
        s.d_year,
        s.month_seq,
        s.i_category,
        s.i_class,
        s.channel,
        s.total_sales,
        s.total_discount,
        s.total_quantity,
        s.total_profit,
        s.distinct_customers,
        s.order_count,
        COALESCE(r.return_quantity, 0) AS return_quantity,
        COALESCE(r.return_amount, 0) AS return_amount
    FROM (
        SELECT * FROM sales_agg
        UNION ALL
        SELECT * FROM store_agg
        UNION ALL
        SELECT * FROM web_agg
    ) s
    LEFT JOIN returns_agg r
        ON s.d_year = r.d_year
        AND s.month_seq = r.month_seq
        AND s.i_category = r.i_category
        AND s.i_class = r.i_class
        AND s.channel = r.channel
)
SELECT
    d_year,
    month_seq,
    i_category,
    i_class,
    channel,
    total_sales,
    total_discount,
    total_sales - total_discount AS net_sales,
    total_quantity,
    CASE WHEN total_quantity = 0 THEN 0 ELSE return_quantity * 100.0 / total_quantity END AS return_rate_pct,
    total_profit,
    distinct_customers,
    order_count,
    SUM(total_sales) OVER (PARTITION BY channel ORDER BY d_year, month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS sales_3_month_ma,
    SUM(total_sales) OVER (PARTITION BY channel, i_category ORDER BY d_year, month_seq ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS sales_12_month_ma
FROM combined
WHERE d_year >= 2000
ORDER BY d_year, month_seq, i_category, i_class, channel
LIMIT 100

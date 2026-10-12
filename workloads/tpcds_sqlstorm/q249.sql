WITH date_range AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
),
catalog_sales_agg AS (
    SELECT
        d.d_date AS sale_date,
        d.d_year,
        d.d_month_seq AS month,
        'Catalog' AS channel,
        SUM(cs.cs_ext_sales_price) AS gross_sales,
        SUM(cs.cs_net_paid_inc_tax) AS net_sales,
        SUM(cs.cs_net_profit) AS profit,
        COUNT(DISTINCT cs.cs_order_number) AS orders
    FROM catalog_sales cs
    JOIN date_range d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date, d.d_year, d.d_month_seq
),
store_sales_agg AS (
    SELECT
        d.d_date AS sale_date,
        d.d_year,
        d.d_month_seq AS month,
        'Store' AS channel,
        SUM(ss.ss_ext_sales_price) AS gross_sales,
        SUM(ss.ss_net_paid_inc_tax) AS net_sales,
        SUM(ss.ss_net_profit) AS profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders
    FROM store_sales ss
    JOIN date_range d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date, d.d_year, d.d_month_seq
),
web_sales_agg AS (
    SELECT
        d.d_date AS sale_date,
        d.d_year,
        d.d_month_seq AS month,
        'Web' AS channel,
        SUM(ws.ws_ext_sales_price) AS gross_sales,
        SUM(ws.ws_net_paid_inc_tax) AS net_sales,
        SUM(ws.ws_net_profit) AS profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders
    FROM web_sales ws
    JOIN date_range d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date, d.d_year, d.d_month_seq
),
catalog_returns_agg AS (
    SELECT
        d.d_date AS return_date,
        d.d_year,
        d.d_month_seq AS month,
        'Catalog' AS channel,
        SUM(cr.cr_net_loss) AS returns_amount
    FROM catalog_returns cr
    JOIN date_range d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date, d.d_year, d.d_month_seq
),
store_returns_agg AS (
    SELECT
        d.d_date AS return_date,
        d.d_year,
        d.d_month_seq AS month,
        'Store' AS channel,
        SUM(sr.sr_net_loss) AS returns_amount
    FROM store_returns sr
    JOIN date_range d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date, d.d_year, d.d_month_seq
),
web_returns_agg AS (
    SELECT
        d.d_date AS return_date,
        d.d_year,
        d.d_month_seq AS month,
        'Web' AS channel,
        SUM(wr.wr_net_loss) AS returns_amount
    FROM web_returns wr
    JOIN date_range d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date, d.d_year, d.d_month_seq
),
returns_combined AS (
    SELECT * FROM catalog_returns_agg
    UNION ALL
    SELECT * FROM store_returns_agg
    UNION ALL
    SELECT * FROM web_returns_agg
),
returns_agg AS (
    SELECT
        return_date,
        d_year,
        month,
        channel,
        SUM(returns_amount) AS total_returns
    FROM returns_combined
    GROUP BY return_date, d_year, month, channel
),
sales_combined AS (
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
final_sales AS (
    SELECT
        sc.sale_date,
        sc.d_year,
        sc.month,
        sc.channel,
        sc.gross_sales,
        sc.net_sales,
        sc.profit,
        sc.orders,
        COALESCE(r.total_returns, 0) AS total_returns,
        sc.net_sales - COALESCE(r.total_returns, 0) AS net_revenue,
        SUM(sc.net_sales - COALESCE(r.total_returns, 0)) OVER (PARTITION BY sc.channel ORDER BY sc.sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_7day_avg_net_rev
    FROM sales_combined sc
    LEFT JOIN returns_agg r
        ON sc.sale_date = r.return_date
       AND sc.channel = r.channel
),
summary AS (
    SELECT
        d_year,
        month,
        channel,
        SUM(gross_sales) AS total_gross_sales,
        SUM(net_sales) AS total_net_sales,
        SUM(profit) AS total_profit,
        SUM(orders) AS total_orders,
        SUM(total_returns) AS total_returns,
        SUM(net_revenue) AS total_net_revenue,
        AVG(moving_7day_avg_net_rev) AS avg_7day_net_rev
    FROM final_sales
    GROUP BY ROLLUP (d_year, month, channel)
)
SELECT *
FROM summary
WHERE d_year IS NOT NULL
ORDER BY d_year, month, channel

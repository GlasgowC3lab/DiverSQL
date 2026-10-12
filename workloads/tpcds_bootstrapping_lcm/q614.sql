WITH sales_agg AS (
    SELECT
        ss_sold_date_sk AS date_sk,
        ss_store_sk AS store_sk,
        SUM(ss_net_paid) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_ext_sales_price
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_store_sk
),
returns_agg AS (
    SELECT
        wr_returned_date_sk AS date_sk,
        SUM(wr_return_amt) AS total_returns,
        SUM(wr_net_loss) AS total_return_loss,
        SUM(wr_return_quantity) AS total_return_quantity
    FROM web_returns
    GROUP BY wr_returned_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    s.s_tax_percentage,
    ws.total_sales,
    ws.total_profit,
    ra.total_returns,
    ra.total_return_loss,
    (ws.total_sales - COALESCE(ra.total_returns, 0)) AS net_sales_after_returns,
    ws.total_quantity,
    ra.total_return_quantity,
    w.web_name,
    w.web_tax_percentage
FROM date_dim d
JOIN sales_agg ws ON ws.date_sk = d.d_date_sk
LEFT JOIN returns_agg ra ON ra.date_sk = d.d_date_sk
JOIN store s ON s.s_store_sk = ws.store_sk
LEFT JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2020
ORDER BY d.d_date, s.s_store_name
LIMIT 100

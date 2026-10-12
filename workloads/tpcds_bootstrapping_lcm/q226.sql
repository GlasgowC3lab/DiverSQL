WITH sales_agg AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales
    GROUP BY ss_store_sk, ss_sold_date_sk
),
returns_agg AS (
    SELECT
        wr_returned_date_sk,
        SUM(wr_return_amt) AS total_returns,
        SUM(wr_return_quantity) AS total_return_qty
    FROM web_returns
    GROUP BY wr_returned_date_sk
)
SELECT
    dd_sales.d_date AS sales_date,
    s.s_store_name,
    s.s_city,
    sales_agg.total_sales,
    COALESCE(returns_agg.total_returns, 0) AS total_returns,
    (sales_agg.total_sales - COALESCE(returns_agg.total_returns, 0)) AS net_revenue,
    sales_agg.sales_cnt,
    COALESCE(returns_agg.total_return_qty, 0) AS total_return_qty,
    sales_agg.total_sales / NULLIF(sales_agg.sales_cnt, 0) AS avg_sale_price,
    ROW_NUMBER() OVER (
        PARTITION BY s.s_store_name
        ORDER BY (sales_agg.total_sales - COALESCE(returns_agg.total_returns, 0)) DESC
    ) AS revenue_rank,
    web_site.web_name,
    web_site.web_state,
    web_site.web_tax_percentage,
    dd_closed.d_date AS store_closed_date,
    dd_close.d_date AS site_close_date
FROM sales_agg
JOIN date_dim dd_sales
    ON sales_agg.ss_sold_date_sk = dd_sales.d_date_sk
JOIN store s
    ON sales_agg.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim dd_closed
    ON s.s_closed_date_sk = dd_closed.d_date_sk
LEFT JOIN returns_agg
    ON returns_agg.wr_returned_date_sk = dd_sales.d_date_sk
LEFT JOIN web_site
    ON web_site.web_open_date_sk = dd_sales.d_date_sk
LEFT JOIN date_dim dd_close
    ON web_site.web_close_date_sk = dd_close.d_date_sk
WHERE dd_sales.d_year = 2022
ORDER BY net_revenue DESC
LIMIT 100

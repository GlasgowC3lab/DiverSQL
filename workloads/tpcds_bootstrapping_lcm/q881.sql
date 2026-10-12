WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_state,
        s.s_market_manager,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(cr.cr_return_amount) AS total_returns,
        SUM(ss.ss_net_profit) - SUM(cr.cr_net_loss) AS net_profit_after_returns,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_product_pages
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_store_sk = ss.ss_store_sk
        AND s.s_closed_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
        AND wp.wp_access_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND s.s_state = 'CA'
        AND wp.wp_type = 'product'
        AND ss.ss_quantity > 0
    GROUP BY
        d.d_year,
        d.d_month_seq,
        s.s_state,
        s.s_market_manager
    HAVING
        SUM(ss.ss_ext_sales_price) > 10000
)
SELECT
    d_year,
    d_month_seq,
    s_state,
    s_market_manager,
    total_sales,
    total_returns,
    net_profit_after_returns,
    avg_discount,
    distinct_product_pages,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100

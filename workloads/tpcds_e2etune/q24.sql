WITH
sales_agg AS (
    SELECT
        ds.d_year,
        ds.d_quarter_name,
        ca_sales.ca_state,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN customer_address ca_sales ON ss.ss_addr_sk = ca_sales.ca_address_sk
    GROUP BY ds.d_year, ds.d_quarter_name, ca_sales.ca_state
),
returns_agg AS (
    SELECT
        dr.d_year,
        dr.d_quarter_name,
        ca_ret.ca_state,
        w.w_warehouse_name,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN customer_address ca_ret ON cr.cr_refunded_addr_sk = ca_ret.ca_address_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY dr.d_year, dr.d_quarter_name, ca_ret.ca_state, w.w_warehouse_name
),
web_agg AS (
    SELECT
        dp.d_year,
        dp.d_quarter_name,
        COUNT(DISTINCT wp.wp_web_page_sk) AS page_access_cnt
    FROM web_page wp
    JOIN date_dim dp ON wp.wp_access_date_sk = dp.d_date_sk
    WHERE wp.wp_type = 'product'
    GROUP BY dp.d_year, dp.d_quarter_name
)
SELECT
    s.d_year,
    s.d_quarter_name,
    s.ca_state,
    s.total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_sales_profit - COALESCE(r.total_return_loss, 0) AS net_margin,
    s.sales_cnt,
    COALESCE(r.returns_cnt, 0) AS returns_cnt,
    r.w_warehouse_name,
    w.page_access_cnt,
    RANK() OVER (PARTITION BY s.d_year ORDER BY s.total_sales_profit - COALESCE(r.total_return_loss, 0) DESC) AS margin_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
    AND s.d_quarter_name = r.d_quarter_name
    AND s.ca_state = r.ca_state
LEFT JOIN web_agg w
    ON s.d_year = w.d_year
    AND s.d_quarter_name = w.d_quarter_name
ORDER BY s.d_year, margin_rank

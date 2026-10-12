WITH combined AS (
    SELECT
        d.d_year,
        i.i_category,
        cs.cs_net_paid AS catalog_sale,
        cr.cr_return_amount AS catalog_return,
        ss.ss_net_paid AS store_sale,
        sr.sr_net_loss AS store_return,
        ws.ws_net_paid AS web_sale,
        wr.wr_net_loss AS web_return
    FROM
        date_dim d
        JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk AND ss.ss_item_sk = i.i_item_sk
        LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_item_sk = i.i_item_sk
        LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    WHERE
        d.d_year = 2001
)
SELECT
    d_year,
    i_category,
    SUM(catalog_sale) AS total_catalog_sales,
    SUM(catalog_return) AS total_catalog_returns,
    SUM(store_sale) AS total_store_sales,
    SUM(store_return) AS total_store_returns,
    SUM(web_sale) AS total_web_sales,
    SUM(web_return) AS total_web_returns
FROM combined
GROUP BY
    d_year,
    i_category
ORDER BY
    total_catalog_sales DESC

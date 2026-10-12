SELECT
    year,
    category,
    brand,
    channel,
    SUM(sales_amount) AS total_sales,
    SUM(return_amount) AS total_returns,
    SUM(sales_amount - return_amount) AS net_sales
FROM (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        i.i_brand AS brand,
        'Catalog' AS channel,
        cs.cs_ext_sales_price AS sales_amount,
        COALESCE(cr.cr_return_amount, 0) AS return_amount
    FROM date_dim d
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001

    UNION ALL

    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        'Store' AS channel,
        ss.ss_ext_sales_price,
        COALESCE(sr.sr_return_amt, 0)
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001

    UNION ALL

    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        'Web' AS channel,
        ws.ws_ext_sales_price,
        COALESCE(wr.wr_return_amt, 0)
    FROM date_dim d
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
) t
GROUP BY year, category, brand, channel
ORDER BY net_sales DESC
LIMIT 100

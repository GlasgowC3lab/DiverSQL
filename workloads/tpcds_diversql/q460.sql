WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_birth_month,
        ds.d_year,
        t.t_hour,
        i.i_item_sk,
        i.i_category,
        ss.ss_ext_sales_price AS store_sales_amt,
        ws.ws_ext_sales_price AS web_sales_amt,
        wr.wr_return_amt AS return_amt
    FROM store_sales ss
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = ds.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = ds.d_date_sk
    WHERE ds.d_year = 2001
      AND i.i_category = 'Sports'
      AND c.c_birth_month = 5
      AND t.t_hour BETWEEN 9 AND 17
),
agg1 AS (
    SELECT
        c_customer_sk,
        i_item_sk,
        i_category,
        SUM(store_sales_amt) AS store_sales,
        SUM(web_sales_amt) AS web_sales,
        SUM(return_amt) AS returns
    FROM base
    GROUP BY GROUPING SETS (
        (c_customer_sk, i_item_sk, i_category),
        (c_customer_sk, i_item_sk),
        (i_category)
    )
),
high_spenders AS (
    SELECT
        c_customer_sk,
        i_item_sk,
        i_category,
        store_sales,
        web_sales,
        returns
    FROM agg1
    WHERE store_sales > 5000
),
raw_combined AS (
    SELECT
        c_customer_sk,
        i_item_sk,
        i_category,
        store_sales,
        web_sales,
        returns
    FROM agg1
    EXCEPT
    SELECT
        c_customer_sk,
        i_item_sk,
        i_category,
        store_sales,
        web_sales,
        returns
    FROM high_spenders
)
SELECT
    rc.c_customer_sk,
    rc.i_item_sk,
    rc.i_category,
    rc.store_sales,
    rc.web_sales,
    rc.returns,
    SUM(rc.store_sales) OVER (
        PARTITION BY rc.i_category
        ORDER BY rc.store_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_store_sales,
    LAG(rc.store_sales) OVER (
        PARTITION BY rc.i_category
        ORDER BY rc.store_sales DESC
    ) AS prev_store_sales
FROM raw_combined rc
WHERE EXISTS (
    SELECT 1 FROM web_sales ws2
    WHERE ws2.ws_item_sk = rc.i_item_sk
      AND ws2.ws_quantity > 0
)
ORDER BY rc.i_category, rc.store_sales DESC
LIMIT 100

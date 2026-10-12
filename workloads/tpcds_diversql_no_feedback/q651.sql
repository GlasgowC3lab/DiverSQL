WITH
    agg_ws AS (
        SELECT
            ws_web_page_sk,
            ws_sold_time_sk,
            sum(ws_ext_sales_price) AS total_sales,
            count(*) AS order_cnt
        FROM web_sales
        WHERE ws_ext_sales_price > 1000
          AND ws_quantity >= 1
          AND ws_ship_cdemo_sk IN (1895897, 1630659)
          AND ws_web_site_sk IN (13, 7)
        GROUP BY ws_web_page_sk, ws_sold_time_sk
    ),
    allowed_pages AS (
        SELECT wp_web_page_sk FROM web_page WHERE wp_url LIKE 'http://www.foo.com%'
        EXCEPT
        SELECT wp_web_page_sk FROM web_page WHERE wp_type = 'ads'
    ),
    joined AS (
        SELECT
            a.ws_web_page_sk,
            a.ws_sold_time_sk,
            a.total_sales,
            a.order_cnt,
            p.wp_url,
            p.wp_type,
            t.t_hour,
            t.t_minute,
            t.t_second
        FROM agg_ws a
        JOIN web_page p
            ON a.ws_web_page_sk = p.wp_web_page_sk
        JOIN time_dim t
            ON a.ws_sold_time_sk = t.t_time_sk
        JOIN allowed_pages ap
            ON a.ws_web_page_sk = ap.wp_web_page_sk
        WHERE t.t_hour BETWEEN 8 AND 17
          AND t.t_second IN (3, 6, 9)
          AND p.wp_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2001-12-31'
          AND p.wp_type = 'home'
    ),
    ranked AS (
        SELECT
            ws_web_page_sk,
            wp_url,
            total_sales,
            order_cnt,
            ROW_NUMBER() OVER (PARTITION BY wp_url ORDER BY total_sales DESC) AS rn
        FROM joined
    )
SELECT
    ws_web_page_sk,
    wp_url,
    total_sales,
    order_cnt,
    rn
FROM ranked
WHERE rn <= 3
  AND total_sales > 20000
UNION DISTINCT
SELECT
    ws_web_page_sk,
    wp_url,
    total_sales,
    order_cnt,
    rn
FROM ranked
WHERE rn <= 3
  AND total_sales BETWEEN 10000 AND 20000
ORDER BY total_sales DESC
LIMIT 100

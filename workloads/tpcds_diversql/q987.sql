WITH
    agg_returning AS (
        SELECT
            wr_returning_customer_sk AS cust_sk,
            wr_web_page_sk,
            wr_reason_sk,
            SUM(wr_return_amt) AS total_return_amt,
            AVG(wr_return_tax) AS avg_tax,
            COUNT(*) AS return_cnt
        FROM tpcds.web_returns
        TABLESAMPLE BERNOULLI (10)
        WHERE wr_return_ship_cost > 100
          AND wr_account_credit > 0
          AND wr_return_amt > 200
        GROUP BY wr_returning_customer_sk, wr_web_page_sk, wr_reason_sk
    ),
    agg_refunded AS (
        SELECT
            wr_refunded_customer_sk AS cust_sk,
            wr_web_page_sk,
            wr_reason_sk,
            SUM(wr_return_amt) AS total_return_amt,
            AVG(wr_return_tax) AS avg_tax,
            COUNT(*) AS return_cnt
        FROM tpcds.web_returns
        TABLESAMPLE BERNOULLI (10)
        WHERE wr_return_ship_cost > 150
          AND wr_account_credit > 50
          AND wr_return_amt > 300
        GROUP BY wr_refunded_customer_sk, wr_web_page_sk, wr_reason_sk
    ),
    reason_array AS (
        SELECT
            r_reason_sk,
            ARRAY[r_reason_desc] AS reason_arr
        FROM tpcds.reason
    )
(
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r_desc AS reason_desc,
        wp.wp_url,
        ar.total_return_amt,
        ar.avg_tax,
        ar.return_cnt
    FROM agg_returning ar
    JOIN tpcds.customer c ON ar.cust_sk = c.c_customer_sk
    JOIN tpcds.web_page wp ON ar.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason_array ra ON ar.wr_reason_sk = ra.r_reason_sk
    CROSS JOIN UNNEST(ra.reason_arr) AS t(r_desc)
    UNION
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r_desc AS reason_desc,
        wp.wp_url,
        ar.total_return_amt,
        ar.avg_tax,
        ar.return_cnt
    FROM agg_refunded ar
    JOIN tpcds.customer c ON ar.cust_sk = c.c_customer_sk
    JOIN tpcds.web_page wp ON ar.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason_array ra ON ar.wr_reason_sk = ra.r_reason_sk
    CROSS JOIN UNNEST(ra.reason_arr) AS t(r_desc)
) EXCEPT (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r_desc AS reason_desc,
        wp.wp_url,
        ar.total_return_amt,
        ar.avg_tax,
        ar.return_cnt
    FROM agg_returning ar
    JOIN tpcds.customer c ON ar.cust_sk = c.c_customer_sk
    JOIN tpcds.web_page wp ON ar.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason_array ra ON ar.wr_reason_sk = ra.r_reason_sk
    CROSS JOIN UNNEST(ra.reason_arr) AS t(r_desc)
    WHERE wp.wp_max_ad_count > 2
      AND wp.wp_link_count > 8
) INTERSECT (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r_desc AS reason_desc,
        wp.wp_url,
        ar.total_return_amt,
        ar.avg_tax,
        ar.return_cnt
    FROM agg_refunded ar
    JOIN tpcds.customer c ON ar.cust_sk = c.c_customer_sk
    JOIN tpcds.web_page wp ON ar.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason_array ra ON ar.wr_reason_sk = ra.r_reason_sk
    CROSS JOIN UNNEST(ra.reason_arr) AS t(r_desc)
    WHERE wp.wp_image_count > 5
)
ORDER BY total_return_amt DESC
LIMIT 100

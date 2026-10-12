WITH agg_page AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_type,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT c_refunded.c_customer_sk) AS distinct_refunded_cust,
        AVG(wr.wr_return_amt) AS avg_return_amt
    FROM web_returns wr
    INNER JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    INNER JOIN customer c_refunded
        ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
    INNER JOIN customer_address ca_refunded
        ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    INNER JOIN household_demographics hd_refunded
        ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    INNER JOIN income_band ib
        ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
    /* additional join to satisfy rule web_page.wp_customer_sk = customer.c_customer_sk */
    INNER JOIN customer c_page
        ON wp.wp_customer_sk = c_page.c_customer_sk
    WHERE ib.ib_upper_bound >= 50000
      AND hd_refunded.hd_dep_count <= 5
      AND wp.wp_char_count > 1000
      AND wp.wp_type = 'Content'
    GROUP BY wp.wp_web_page_sk, wp.wp_url, wp.wp_type
),
ranked AS (
    SELECT
        wp_type,
        wp_url,
        total_return_amt,
        total_return_qty,
        distinct_refunded_cust,
        avg_return_amt,
        ROW_NUMBER() OVER (PARTITION BY wp_type ORDER BY total_return_amt DESC) AS rank,
        SUM(total_return_amt) OVER (
            PARTITION BY wp_type
            ORDER BY total_return_amt DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total_return_amt,
        LAG(total_return_amt) OVER (PARTITION BY wp_type ORDER BY total_return_amt DESC) AS prev_total_return_amt
    FROM agg_page
)
SELECT
    wp_type,
    wp_url,
    total_return_amt,
    total_return_qty,
    distinct_refunded_cust,
    avg_return_amt,
    rank,
    running_total_return_amt,
    prev_total_return_amt
FROM ranked
WHERE rank <= 5
ORDER BY wp_type, rank
LIMIT 100

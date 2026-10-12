WITH filtered_returns AS (
    SELECT
        wr.wr_refunded_customer_sk,
        wr.wr_returning_customer_sk,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_web_page_sk
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2450800 AND 2450900
),
joined_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        c.c_birth_year,
        c.c_preferred_cust_flag,
        wp.wp_type,
        wp.wp_url,
        fr.wr_return_amt,
        fr.wr_net_loss,
        fr.wr_return_quantity
    FROM filtered_returns fr
    JOIN customer c
        ON fr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON fr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_month IN (4, 10, 12)
      AND wp.wp_type = 'product'
),
aggregated AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_birth_month,
        c_birth_year,
        wp_type,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount,
        SUM(wr_net_loss) AS total_net_loss,
        AVG(wr_return_quantity) AS avg_return_qty,
        COUNT(DISTINCT wp_url) AS distinct_pages
    FROM joined_data
    GROUP BY
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_birth_month,
        c_birth_year,
        wp_type
)
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    c_birth_month,
    c_birth_year,
    wp_type,
    total_returns,
    total_return_amount,
    total_net_loss,
    avg_return_qty,
    distinct_pages,
    RANK() OVER (PARTITION BY c_birth_month ORDER BY total_net_loss DESC) AS month_net_loss_rank
FROM aggregated
ORDER BY c_birth_month, month_net_loss_rank
LIMIT 100

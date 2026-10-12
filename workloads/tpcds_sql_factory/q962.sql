WITH catalog_cust AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt,
        MIN(i.i_color) AS first_color
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450500 AND 2450600
    GROUP BY cr.cr_returning_customer_sk
    HAVING COUNT(*) >= 2
),
web_cust AS (
    SELECT
        wr.wr_returning_customer_sk AS customer_sk,
        SUM(wr.wr_return_amt) AS web_return_amount,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt,
        MIN(i.i_color) AS first_color
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450500 AND 2450600
    GROUP BY wr.wr_returning_customer_sk
    HAVING SUM(wr.wr_return_amt) > 400
),
combined_cust AS (
    SELECT
        COALESCE(c.customer_sk, w.customer_sk) AS customer_sk,
        COALESCE(c.catalog_return_amount, 0) + COALESCE(w.web_return_amount, 0) AS total_return_amount,
        COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss,
        COALESCE(c.catalog_return_cnt, 0) + COALESCE(w.web_return_cnt, 0) AS total_return_cnt,
        CASE WHEN COALESCE(c.first_color, w.first_color) = 'Red' THEN 1 ELSE 0 END AS red_color_flag,
        CASE
            WHEN COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) > 10000 THEN 'Very High'
            WHEN COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) > 5000 THEN 'High'
            ELSE 'Normal'
        END AS loss_category
    FROM catalog_cust c
    FULL OUTER JOIN web_cust w ON c.customer_sk = w.customer_sk
)
SELECT
    customer_sk,
    total_return_amount,
    total_net_loss,
    total_return_cnt,
    red_color_flag,
    loss_category,
    ROW_NUMBER() OVER (PARTITION BY loss_category ORDER BY total_return_cnt DESC) AS cnt_rank,
    PERCENT_RANK() OVER (PARTITION BY loss_category ORDER BY total_return_amount DESC) AS amount_percentile,
    SUM(total_return_amount) OVER (PARTITION BY loss_category ORDER BY total_return_amount ASC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS reverse_cumulative_amount
FROM combined_cust
WHERE red_color_flag = 1
ORDER BY total_net_loss DESC
LIMIT 15

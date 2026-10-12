WITH catalog_cust AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt,
        MIN(i.i_color) AS first_color
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_returned_date_sk >= 2450200
    GROUP BY cr.cr_returning_customer_sk
    HAVING SUM(cr.cr_return_amount) > 800
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
    WHERE wr.wr_returned_date_sk >= 2450200
    GROUP BY wr.wr_returning_customer_sk
    HAVING COUNT(*) >= 2
),
combined_cust AS (
    SELECT
        COALESCE(c.customer_sk, w.customer_sk) AS customer_sk,
        COALESCE(c.catalog_return_amount, 0) + COALESCE(w.web_return_amount, 0) AS total_return_amount,
        COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss,
        COALESCE(c.catalog_return_cnt, 0) + COALESCE(w.web_return_cnt, 0) AS total_return_cnt,
        CASE
            WHEN COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) > 9000 THEN 'Very High Loss'
            WHEN COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) > 4000 THEN 'High Loss'
            ELSE 'Low/Medium Loss'
        END AS loss_category,
        COALESCE(c.first_color, w.first_color) AS representative_color
    FROM catalog_cust c
    FULL OUTER JOIN web_cust w ON c.customer_sk = w.customer_sk
)
SELECT
    customer_sk,
    total_return_amount,
    total_net_loss,
    total_return_cnt,
    loss_category,
    representative_color,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank,
    PERCENT_RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_percentile,
    SUM(total_net_loss) OVER (ORDER BY total_net_loss DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss
FROM combined_cust
WHERE total_return_cnt >= 3 AND loss_category = 'High Loss'
ORDER BY total_net_loss DESC
LIMIT 8

WITH catalog_cust AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt,
        COUNT(DISTINCT i.i_brand) AS distinct_brand_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450300 AND 2450900
    GROUP BY cr.cr_returning_customer_sk
    HAVING COUNT(DISTINCT i.i_brand) >= 2
),
web_cust AS (
    SELECT
        wr.wr_returning_customer_sk AS customer_sk,
        SUM(wr.wr_return_amt) AS web_return_amount,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt,
        COUNT(DISTINCT i.i_brand) AS distinct_brand_cnt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450300 AND 2450900
    GROUP BY wr.wr_returning_customer_sk
    HAVING SUM(wr.wr_return_amt) > 500
),
combined_cust AS (
    SELECT
        COALESCE(c.customer_sk, w.customer_sk) AS customer_sk,
        COALESCE(c.catalog_return_amount, 0) + COALESCE(w.web_return_amount, 0) AS total_return_amount,
        COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss,
        COALESCE(c.catalog_return_cnt, 0) + COALESCE(w.web_return_cnt, 0) AS total_return_cnt,
        COALESCE(c.distinct_brand_cnt, 0) + COALESCE(w.distinct_brand_cnt, 0) AS total_distinct_brands,
        CASE
            WHEN COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) > 11000 THEN 'Very High Loss'
            WHEN COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) > 6000 THEN 'High Loss'
            WHEN COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) > 2000 THEN 'Medium Loss'
            ELSE 'Low Loss'
        END AS loss_category
    FROM catalog_cust c
    FULL OUTER JOIN web_cust w ON c.customer_sk = w.customer_sk
)
SELECT
    customer_sk,
    total_return_amount,
    total_net_loss,
    total_return_cnt,
    total_distinct_brands,
    loss_category,
    ROW_NUMBER() OVER (PARTITION BY loss_category ORDER BY total_distinct_brands DESC) AS brand_rank,
    PERCENT_RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_percentile,
    SUM(total_return_amount) OVER (PARTITION BY loss_category ORDER BY total_return_amount DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_amount_by_category
FROM combined_cust
WHERE total_distinct_brands >= 3
ORDER BY total_net_loss DESC
LIMIT 14

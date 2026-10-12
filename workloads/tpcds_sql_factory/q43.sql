WITH catalog_cust AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt,
        ARRAY_AGG(DISTINCT i.i_brand) AS catalog_brands,
        COUNT(DISTINCT cr.cr_returned_time_sk) AS distinct_return_times
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY cr.cr_returning_customer_sk
),
web_cust AS (
    SELECT
        wr.wr_returning_customer_sk AS customer_sk,
        SUM(wr.wr_return_amt) AS web_return_amount,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt,
        ARRAY_AGG(DISTINCT i.i_brand) AS web_brands,
        COUNT(DISTINCT wr.wr_returned_time_sk) AS distinct_web_return_times
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY wr.wr_returning_customer_sk
),
combined_cust AS (
    SELECT
        COALESCE(c.customer_sk, w.customer_sk) AS customer_sk,
        COALESCE(c.catalog_return_amount, 0) + COALESCE(w.web_return_amount, 0) AS total_return_amount,
        COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss,
        COALESCE(c.catalog_return_cnt, 0) + COALESCE(w.web_return_cnt, 0) AS total_return_cnt,
        COALESCE(c.distinct_return_times, 0) + COALESCE(w.distinct_web_return_times, 0) AS total_distinct_return_times,
        CASE
            WHEN COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) > 6000 THEN 'High Loss'
            WHEN COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) > 1500 THEN 'Medium Loss'
            ELSE 'Low Loss'
        END AS loss_category,
        ARRAY_JOIN(COALESCE(c.catalog_brands, ARRAY[]), ', ') AS catalog_brands_str,
        ARRAY_JOIN(COALESCE(w.web_brands, ARRAY[]), ', ') AS web_brands_str
    FROM catalog_cust c
    FULL OUTER JOIN web_cust w ON c.customer_sk = w.customer_sk
)
SELECT
    customer_sk,
    total_return_amount,
    total_net_loss,
    total_return_cnt,
    total_distinct_return_times,
    loss_category,
    catalog_brands_str,
    web_brands_str,
    NTILE(4) OVER (ORDER BY total_return_amount DESC) AS amount_quartile,
    SUM(total_net_loss) OVER (ORDER BY total_return_amount DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss,
    ROW_NUMBER() OVER (PARTITION BY loss_category ORDER BY total_return_cnt DESC) AS rank_within_loss_category
FROM combined_cust
WHERE total_distinct_return_times > 1
ORDER BY total_return_amount DESC
LIMIT 30

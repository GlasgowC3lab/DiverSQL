WITH catalog_cust AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt,
        ARRAY_AGG(DISTINCT i.i_category) FILTER (WHERE i.i_category IS NOT NULL) AS catalog_categories
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450500 AND 2451500
    GROUP BY cr.cr_returning_customer_sk
    HAVING SUM(cr.cr_return_amount) BETWEEN 500 AND 2000
),
web_cust AS (
    SELECT
        wr.wr_returning_customer_sk AS customer_sk,
        SUM(wr.wr_return_amt) AS web_return_amount,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt,
        ARRAY_AGG(DISTINCT i.i_category) FILTER (WHERE i.i_category IS NOT NULL) AS web_categories
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450500 AND 2451500
    GROUP BY wr.wr_returning_customer_sk
    HAVING COUNT(*) >= 3
),
combined_cust AS (
    SELECT
        COALESCE(c.customer_sk, w.customer_sk) AS customer_sk,
        COALESCE(c.catalog_return_amount, 0) + COALESCE(w.web_return_amount, 0) AS total_return_amount,
        COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss,
        COALESCE(c.catalog_return_cnt, 0) + COALESCE(w.web_return_cnt, 0) AS total_return_cnt,
        CASE
            WHEN COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) > 15000 THEN 'Very High Loss'
            WHEN COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) > 8000 THEN 'High Loss'
            WHEN COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) > 2000 THEN 'Medium Loss'
            ELSE 'Low Loss'
        END AS loss_category,
        ARRAY_JOIN(COALESCE(c.catalog_categories, ARRAY[]), ', ') AS catalog_categories_str,
        ARRAY_JOIN(COALESCE(w.web_categories, ARRAY[]), ', ') AS web_categories_str
    FROM catalog_cust c
    FULL OUTER JOIN web_cust w ON c.customer_sk = w.customer_sk
)
SELECT
    customer_sk,
    total_return_amount,
    total_net_loss,
    total_return_cnt,
    loss_category,
    catalog_categories_str,
    web_categories_str,
    ROW_NUMBER() OVER (PARTITION BY loss_category ORDER BY total_return_amount DESC) AS loss_category_rank,
    NTILE(4) OVER (ORDER BY total_net_loss DESC) AS net_loss_quartile,
    AVG(total_return_amount) OVER (PARTITION BY loss_category) AS avg_return_by_loss
FROM combined_cust
WHERE total_return_cnt >= 2 AND loss_category IN ('High Loss', 'Very High Loss')
ORDER BY total_net_loss DESC
LIMIT 10

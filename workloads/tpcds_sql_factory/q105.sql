WITH catalog_cust AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        AVG(cr.cr_return_amount) FILTER (WHERE cr.cr_return_amount > 0) AS avg_catalog_return_amount,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt,
        ARRAY_AGG(DISTINCT i.i_brand) AS catalog_brands,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY cr.cr_returning_customer_sk
    HAVING SUM(cr.cr_return_quantity) > 10
),
web_cust AS (
    SELECT
        wr.wr_returning_customer_sk AS customer_sk,
        AVG(wr.wr_return_amt) FILTER (WHERE wr.wr_return_amt > 0) AS avg_web_return_amount,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt,
        ARRAY_AGG(DISTINCT i.i_brand) AS web_brands,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY wr.wr_returning_customer_sk
    HAVING SUM(wr.wr_return_quantity) > 10
),
combined_cust AS (
    SELECT
        COALESCE(c.customer_sk, w.customer_sk) AS customer_sk,
        COALESCE(c.avg_catalog_return_amount, 0) + COALESCE(w.avg_web_return_amount, 0) AS total_avg_return_amount,
        COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss,
        COALESCE(c.catalog_return_cnt, 0) + COALESCE(w.web_return_cnt, 0) AS total_return_cnt,
        COALESCE(c.total_return_qty, 0) + COALESCE(w.total_return_qty, 0) AS total_return_quantity,
        CASE
            WHEN COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) > 3500 THEN 'High Loss'
            ELSE 'Low/Medium Loss'
        END AS loss_category,
        ARRAY_JOIN(COALESCE(c.catalog_brands, ARRAY[]), ', ') AS catalog_brands_str,
        ARRAY_JOIN(COALESCE(w.web_brands, ARRAY[]), ', ') AS web_brands_str,
        NTILE(4) OVER (ORDER BY COALESCE(c.catalog_net_loss,0)+COALESCE(w.web_net_loss,0) DESC) AS loss_quartile
    FROM catalog_cust c
    FULL OUTER JOIN web_cust w ON c.customer_sk = w.customer_sk
)
SELECT
    customer_sk,
    total_avg_return_amount,
    total_net_loss,
    total_return_cnt,
    total_return_quantity,
    loss_category,
    loss_quartile,
    catalog_brands_str,
    web_brands_str,
    COUNT(*) OVER (PARTITION BY loss_quartile) AS customers_in_quartile,
    AVG(total_return_quantity) OVER (PARTITION BY loss_category) AS avg_qty_per_category
FROM combined_cust
WHERE loss_quartile IN (1,2)
ORDER BY loss_quartile, total_net_loss DESC
LIMIT 40

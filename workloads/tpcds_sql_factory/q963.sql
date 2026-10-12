WITH catalog_cust AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        AVG(cr.cr_return_amount) AS avg_catalog_return_amount,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt,
        MAX(i.i_brand) AS top_brand
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450300 AND 2450900
      AND cr.cr_return_quantity > 1
    GROUP BY cr.cr_returning_customer_sk
    HAVING SUM(cr.cr_net_loss) > 2000
),
web_cust AS (
    SELECT
        wr.wr_returning_customer_sk AS customer_sk,
        AVG(wr.wr_return_amt) AS avg_web_return_amount,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt,
        MIN(i.i_brand) AS min_brand
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450300 AND 2450900
      AND wr.wr_return_quantity > 1
    GROUP BY wr.wr_returning_customer_sk
    HAVING COUNT(*) >= 5
),
combined_cust AS (
    SELECT
        COALESCE(c.customer_sk, w.customer_sk) AS customer_sk,
        COALESCE(c.avg_catalog_return_amount, 0) * COALESCE(w.avg_web_return_amount, 0) AS combined_avg_return_amount,
        COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss,
        COALESCE(c.catalog_return_cnt, 0) + COALESCE(w.web_return_cnt, 0) AS total_return_cnt,
        CASE
            WHEN COALESCE(c.top_brand, w.min_brand) IS NOT NULL THEN 1 ELSE 0
        END AS has_brand_flag,
        CASE
            WHEN COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) > 12000 THEN 'Severe'
            WHEN COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) > 6000 THEN 'Moderate'
            ELSE 'Mild'
        END AS loss_category
    FROM catalog_cust c
    FULL OUTER JOIN web_cust w ON c.customer_sk = w.customer_sk
)
SELECT
    customer_sk,
    combined_avg_return_amount,
    total_net_loss,
    total_return_cnt,
    has_brand_flag,
    loss_category,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank,
    NTILE(4) OVER (ORDER BY combined_avg_return_amount DESC) AS quartile_return_amount,
    SUM(total_net_loss) OVER (PARTITION BY loss_category) AS net_loss_by_category
FROM combined_cust
WHERE has_brand_flag = 1
ORDER BY total_net_loss DESC
LIMIT 12

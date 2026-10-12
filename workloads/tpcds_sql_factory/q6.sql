WITH catalog_agg AS (
    SELECT
        cr_item_sk AS item_sk,
        SUM(cr_net_loss) AS catalog_net_loss,
        SUM(cr_fee) AS catalog_fee,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns
    GROUP BY cr_item_sk
),
web_agg AS (
    SELECT
        wr_item_sk AS item_sk,
        SUM(wr_net_loss) AS web_net_loss,
        SUM(wr_fee) AS web_fee,
        COUNT(*) AS web_return_cnt
    FROM web_returns
    GROUP BY wr_item_sk
),
combined AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss,
        COALESCE(c.catalog_fee, 0) + COALESCE(w.web_fee, 0) AS total_fee,
        COALESCE(c.catalog_return_cnt, 0) + COALESCE(w.web_return_cnt, 0) AS total_return_cnt,
        CASE
            WHEN COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) > 10000 THEN 'Critical'
            WHEN COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) > 5000 THEN 'High'
            WHEN COALESCE(c.catalog_net_loss, 0) + COALESCE(w.web_net_loss, 0) > 1000 THEN 'Medium'
            ELSE 'Low'
        END AS loss_severity
    FROM item i
    LEFT JOIN catalog_agg c ON i.i_item_sk = c.item_sk
    LEFT JOIN web_agg w ON i.i_item_sk = w.item_sk
)
SELECT
    i_item_sk,
    i_product_name,
    i_brand,
    i_category,
    total_net_loss,
    total_fee,
    total_return_cnt,
    loss_severity,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank,
    SUM(total_net_loss) OVER (ORDER BY total_net_loss DESC
                              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss
FROM combined
WHERE total_return_cnt > 0
ORDER BY total_net_loss DESC
LIMIT 10

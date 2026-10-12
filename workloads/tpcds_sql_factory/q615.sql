WITH item_sales AS (
    SELECT
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
),
item_returns AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_net_loss) AS total_loss,
        COUNT(*) AS return_transactions
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
item_metrics AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        COALESCE(s.total_profit, 0) AS total_profit,
        COALESCE(r.total_loss, 0) AS total_loss,
        CASE
            WHEN (COALESCE(s.total_profit, 0) + COALESCE(r.total_loss, 0)) = 0 THEN 0
            ELSE COALESCE(r.total_loss, 0) / (COALESCE(s.total_profit, 0) + COALESCE(r.total_loss, 0))
        END AS loss_ratio,
        (COALESCE(s.total_profit, 0) - COALESCE(r.total_loss, 0)) AS net_gain
    FROM item i
    LEFT JOIN item_sales s ON i.i_item_sk = s.ss_item_sk
    LEFT JOIN item_returns r ON i.i_item_sk = r.cr_item_sk
)
SELECT
    im.i_item_sk,
    im.i_product_name,
    im.i_category,
    im.total_profit,
    im.total_loss,
    im.loss_ratio,
    CASE
        WHEN im.loss_ratio > 0.2 THEN 'ALERT'
        ELSE 'OK'
    END AS status,
    RANK() OVER (ORDER BY im.loss_ratio DESC) AS loss_rank
FROM item_metrics im
WHERE im.loss_ratio IS NOT NULL
ORDER BY loss_rank
LIMIT 5

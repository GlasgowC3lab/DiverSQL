WITH daily_returns AS (
    SELECT
        cp.cp_type AS cp_type,
        i.i_category AS category,
        cp.cp_start_date_sk AS start_date_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_txn_cnt
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY cp.cp_type, i.i_category, cp.cp_start_date_sk
)
SELECT
    cp_type,
    category,
    start_date_sk,
    total_return_amount,
    total_net_loss,
    return_txn_cnt,
    SUM(total_return_amount) OVER (PARTITION BY cp_type ORDER BY start_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amount_by_type,
    LAG(total_net_loss) OVER (PARTITION BY cp_type, category ORDER BY start_date_sk) AS prev_net_loss,
    CASE
        WHEN LAG(total_net_loss) OVER (PARTITION BY cp_type, category ORDER BY start_date_sk) IS NULL THEN 'N/A'
        WHEN total_net_loss > LAG(total_net_loss) OVER (PARTITION BY cp_type, category ORDER BY start_date_sk) THEN 'INCREASE'
        ELSE 'DECREASE_OR_SAME'
    END AS net_loss_trend,
    ROW_NUMBER() OVER (PARTITION BY cp_type ORDER BY total_return_amount DESC) AS return_amount_rank_within_type
FROM daily_returns
WHERE total_return_amount > 0
ORDER BY cp_type, start_date_sk

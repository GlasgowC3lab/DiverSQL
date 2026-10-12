WITH returns_detail AS (
    SELECT
        d.d_date,
        d.d_holiday,
        wr.wr_reason_sk,
        SUM(wr.wr_net_loss) AS loss_by_reason,
        SUM(wr.wr_return_quantity) AS qty_by_reason,
        COUNT(*) AS cnt_by_reason
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_date, d.d_holiday, wr.wr_reason_sk
),
ranked_reason AS (
    SELECT
        d_date,
        CASE WHEN d_holiday = 'Y' THEN 'Holiday' ELSE 'Non-Holiday' END AS holiday_flag,
        wr_reason_sk,
        loss_by_reason,
        qty_by_reason,
        cnt_by_reason,
        DENSE_RANK() OVER (PARTITION BY CASE WHEN d_holiday = 'Y' THEN 'Holiday' ELSE 'Non-Holiday' END ORDER BY loss_by_reason DESC) AS reason_rank
    FROM returns_detail
)
SELECT
    holiday_flag,
    d_date,
    wr_reason_sk,
    loss_by_reason,
    qty_by_reason,
    cnt_by_reason,
    reason_rank
FROM ranked_reason
WHERE reason_rank <= 3
ORDER BY holiday_flag, reason_rank

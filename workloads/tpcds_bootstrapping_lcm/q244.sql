WITH returns_by_store AS (
    SELECT
        d.d_year AS calendar_year,
        d.d_current_month AS calendar_month,
        s.s_division_name AS division_name,
        r.r_reason_desc AS reason_desc,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_quantity) AS total_quantity,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_fee) AS avg_fee,
        SUM(wr.wr_return_tax) AS total_tax,
        SUM(wr.wr_return_ship_cost) AS total_ship_cost
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY
        d.d_year,
        d.d_current_month,
        s.s_division_name,
        r.r_reason_desc
),
store_rankings AS (
    SELECT
        calendar_year,
        calendar_month,
        division_name,
        reason_desc,
        return_cnt,
        total_quantity,
        total_return_amt,
        total_net_loss,
        avg_fee,
        total_tax,
        total_ship_cost,
        ROW_NUMBER() OVER (
            PARTITION BY calendar_year, calendar_month
            ORDER BY total_return_amt DESC
        ) AS rank_by_return_amount
    FROM returns_by_store
)
SELECT
    calendar_year,
    calendar_month,
    division_name,
    reason_desc,
    return_cnt,
    total_quantity,
    total_return_amt,
    total_net_loss,
    ROUND(total_net_loss / NULLIF(total_return_amt, 0), 4) AS loss_ratio,
    CASE
        WHEN total_net_loss > 0 THEN 'Loss'
        WHEN total_net_loss < 0 THEN 'Gain'
        ELSE 'Break-even'
    END AS net_outcome,
    rank_by_return_amount,
    ROUND(total_net_loss / NULLIF(SUM(total_net_loss) OVER (
        PARTITION BY calendar_year, calendar_month
    ), 0), 4) AS net_loss_share_month,
    SUM(total_return_amt) OVER (
        PARTITION BY calendar_year, calendar_month
    ) AS month_total_return_amt
FROM store_rankings
WHERE rank_by_return_amount <= 5
ORDER BY
    calendar_year,
    calendar_month,
    rank_by_return_amount

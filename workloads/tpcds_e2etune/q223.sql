WITH band_returns AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(wr.wr_return_amt) AS avg_return_amount,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
        AVG(wr.wr_net_loss) AS avg_net_loss,
        SUM(wr.wr_account_credit) AS total_account_credit,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
    FROM
        web_returns wr
    JOIN
        income_band ib
        ON wr.wr_return_amt BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE
        wr.wr_return_quantity > 0
        AND wr.wr_fee > 5.00
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    HAVING
        SUM(wr.wr_return_amt) > 1000
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_returns,
    total_return_amount,
    avg_return_amount,
    total_return_amount_inc_tax,
    avg_net_loss,
    total_account_credit,
    distinct_orders,
    RANK() OVER (ORDER BY total_return_amount DESC) AS revenue_rank
FROM
    band_returns
ORDER BY
    total_return_amount DESC
LIMIT 10

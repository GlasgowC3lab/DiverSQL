WITH agg AS (
    SELECT
        d.d_year AS d_year,
        d.d_quarter_name AS d_quarter_name,
        r.r_reason_desc AS r_reason_desc,
        s.s_state AS s_state,
        COUNT(DISTINCT wr.wr_order_number) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(hd_refunded.hd_income_band_sk) AS avg_income_band_refunded,
        AVG(hd_returning.hd_income_band_sk) AS avg_income_band_returning,
        SUM(CASE WHEN wr.wr_return_quantity > 1 THEN wr.wr_return_quantity ELSE 0 END) AS total_multi_item_returns,
        COUNT(DISTINCT s.s_store_id) AS num_stores_closed,
        ROUND(SUM(wr.wr_return_amt) / NULLIF(COUNT(DISTINCT s.s_store_id), 0), 2) AS avg_return_per_closed_store
    FROM date_dim d
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd_refunded ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2019 AND 2021
      AND s.s_state IS NOT NULL
    GROUP BY
        d.d_year,
        d.d_quarter_name,
        r.r_reason_desc,
        s.s_state
    HAVING COUNT(DISTINCT wr.wr_order_number) > 10
)
SELECT
    d_year,
    d_quarter_name,
    r_reason_desc,
    s_state,
    num_returns,
    total_return_amount,
    total_net_loss,
    avg_income_band_refunded,
    avg_income_band_returning,
    total_multi_item_returns,
    num_stores_closed,
    avg_return_per_closed_store,
    RANK() OVER (PARTITION BY d_year, d_quarter_name ORDER BY total_net_loss DESC) AS reason_net_loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100

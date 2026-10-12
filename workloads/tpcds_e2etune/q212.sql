WITH returns_on_closed_date AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_market_desc,
        d.d_fy_quarter_seq,
        COUNT(DISTINCT wr.wr_order_number) AS num_returns,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_net_loss) AS avg_net_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax
    FROM
        store s
    JOIN
        date_dim d ON s.s_closed_date_sk = d.d_date_sk
    JOIN
        web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_holiday = 'Y'
        AND d.d_fy_year = 1902
        AND s.s_state = 'CA'
        AND wr.wr_return_quantity > 0
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_market_desc,
        d.d_fy_quarter_seq
    HAVING
        SUM(wr.wr_net_loss) > 0
)
SELECT
    r.*,
    ROW_NUMBER() OVER (PARTITION BY r.s_state ORDER BY r.total_net_loss DESC) AS rn_state
FROM
    returns_on_closed_date r
ORDER BY
    r.total_net_loss DESC,
    r.s_store_name
LIMIT 100

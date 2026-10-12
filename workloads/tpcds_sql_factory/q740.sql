WITH store_net_loss AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_date,
        SUM(wr.wr_net_loss) AS net_loss
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2021
    GROUP BY s.s_store_id, s.s_store_name, d.d_date
)
SELECT
    snl.s_store_id,
    snl.s_store_name,
    snl.d_date,
    snl.net_loss,
    LAG(snl.net_loss) OVER (ORDER BY snl.d_date) AS prev_net_loss,
    CASE
        WHEN snl.net_loss > COALESCE(LAG(snl.net_loss) OVER (ORDER BY snl.d_date), 0) THEN 'INCREASED'
        ELSE 'DECREASED_OR_EQUAL'
    END AS net_loss_trend,
    RANK() OVER (ORDER BY snl.net_loss DESC) AS loss_rank
FROM store_net_loss snl
ORDER BY loss_rank

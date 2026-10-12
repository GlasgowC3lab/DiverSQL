WITH store_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_division_name,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(*) AS sales_transactions,
        RANK() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state IN ('CA', 'TX', 'NY')
      AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY s.s_store_id, s.s_store_name, s.s_state, s.s_division_name
),
reason_agg AS (
    SELECT
        r.r_reason_desc,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_transactions,
        RANK() OVER (ORDER BY SUM(wr.wr_net_loss) DESC) AS loss_rank
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY r.r_reason_desc
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.s_state,
    sa.s_division_name,
    sa.total_net_profit,
    sa.avg_discount,
    ra.r_reason_desc,
    ra.total_net_loss
FROM store_agg sa
JOIN reason_agg ra ON sa.profit_rank = ra.loss_rank
WHERE sa.profit_rank <= 10
ORDER BY sa.total_net_profit DESC

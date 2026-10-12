WITH sr_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        r.r_reason_desc,
        t.t_hour,
        c.c_birth_year,
        SUM(sr.sr_net_loss) AS grp_net_loss,
        AVG(sr.sr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
        COUNT(*) AS grp_return_cnt,
        SUM(sr.sr_return_quantity) AS grp_return_qty
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451100 AND 2451200
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        r.r_reason_desc,
        t.t_hour,
        c.c_birth_year
),

store_totals AS (
    SELECT
        s_store_sk,
        s_store_name,
        SUM(grp_net_loss) AS store_total_net_loss,
        SUM(grp_return_cnt) AS store_total_return_cnt,
        SUM(grp_return_qty) AS store_total_return_qty
    FROM sr_agg
    GROUP BY s_store_sk, s_store_name
),

store_rank AS (
    SELECT
        s_store_sk,
        s_store_name,
        store_total_net_loss,
        store_total_return_cnt,
        store_total_return_qty,
        RANK() OVER (ORDER BY store_total_net_loss DESC) AS store_net_loss_rank
    FROM store_totals
),

sr_with_rank AS (
    SELECT
        a.s_store_sk,
        a.s_store_name,
        a.r_reason_desc,
        a.t_hour,
        a.c_birth_year,
        a.grp_net_loss,
        a.avg_return_amt_inc_tax,
        a.grp_return_cnt,
        a.grp_return_qty,
        r.store_total_net_loss,
        r.store_total_return_cnt,
        r.store_total_return_qty,
        r.store_net_loss_rank
    FROM sr_agg a
    JOIN store_rank r ON a.s_store_sk = r.s_store_sk
)
SELECT
    s_store_sk,
    s_store_name,
    r_reason_desc,
    t_hour,
    c_birth_year,
    grp_net_loss,
    avg_return_amt_inc_tax,
    grp_return_cnt,
    grp_return_qty,
    store_total_net_loss,
    store_total_return_cnt,
    store_total_return_qty,
    store_net_loss_rank
FROM sr_with_rank
WHERE store_net_loss_rank <= 10
ORDER BY store_net_loss_rank, grp_net_loss DESC

SELECT
    t.cp_department,
    t.cp_type,
    t.s_store_name,
    t.s_city,
    t.r_reason_desc,
    t.return_count,
    t.total_return_quantity,
    t.total_return_amount,
    t.total_net_loss,
    t.avg_return_amount,
    t.avg_net_loss_per_item,
    DENSE_RANK() OVER (PARTITION BY t.cp_department ORDER BY t.total_net_loss DESC) AS net_loss_rank
FROM (
    SELECT
        cp.cp_department,
        cp.cp_type,
        s.s_store_name,
        s.s_city,
        r.r_reason_desc,
        COUNT(*) AS return_count,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amount,
        SUM(wr.wr_net_loss) / NULLIF(SUM(wr.wr_return_quantity), 0) AS avg_net_loss_per_item
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    CROSS JOIN catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
    WHERE d_ret.d_year = 2022
      AND d_ret.d_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    GROUP BY
        cp.cp_department,
        cp.cp_type,
        s.s_store_name,
        s.s_city,
        r.r_reason_desc
) t
ORDER BY t.total_net_loss DESC
LIMIT 100

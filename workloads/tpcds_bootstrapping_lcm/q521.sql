WITH returns_summary AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        t.t_minute,
        s.s_store_id,
        s.s_city,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        COUNT(*) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_fee) AS avg_fee
    FROM web_returns wr
    INNER JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    INNER JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    INNER JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    INNER JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    GROUP BY
        d.d_date,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        t.t_minute,
        s.s_store_id,
        s.s_city,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number
)
SELECT
    rs.d_date,
    rs.d_year,
    rs.d_month_seq,
    rs.t_hour,
    rs.t_minute,
    rs.s_store_id,
    rs.s_city,
    rs.cp_catalog_number,
    rs.cp_catalog_page_number,
    rs.num_returns,
    rs.total_return_amount,
    rs.total_net_loss,
    rs.avg_fee,
    ROW_NUMBER() OVER (ORDER BY rs.total_net_loss DESC) AS net_loss_rank
FROM returns_summary rs
ORDER BY rs.total_net_loss DESC
LIMIT 100

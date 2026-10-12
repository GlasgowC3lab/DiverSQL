SELECT
    cp_catalog_page_id,
    cp_type,
    start_year,
    start_month_seq,
    end_year,
    end_month_seq,
    s_store_id,
    s_manager,
    s_state,
    web_site_id,
    web_name,
    web_state,
    site_close_year,
    return_count,
    total_return_amount,
    avg_net_loss,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_type,
        d_start.d_year AS start_year,
        d_start.d_month_seq AS start_month_seq,
        d_end.d_year AS end_year,
        d_end.d_month_seq AS end_month_seq,
        s.s_store_id,
        s.s_manager,
        s.s_state,
        ws.web_site_id,
        ws.web_name,
        ws.web_state,
        d_close.d_year AS site_close_year,
        COUNT(wr.wr_order_number) AS return_count,
        SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(wr.wr_net_loss) AS avg_net_loss
    FROM catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_end.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_start.d_date_sk
    JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_type,
        d_start.d_year,
        d_start.d_month_seq,
        d_end.d_year,
        d_end.d_month_seq,
        s.s_store_id,
        s.s_manager,
        s.s_state,
        ws.web_site_id,
        ws.web_name,
        ws.web_state,
        d_close.d_year
) AS agg
ORDER BY total_return_amount DESC
LIMIT 100

SELECT
    agg.d_year,
    agg.d_month_seq,
    agg.s_store_name,
    agg.s_city,
    agg.r_reason_desc,
    agg.total_returns,
    agg.total_net_loss,
    agg.avg_return_tax,
    agg.distinct_pages_created,
    agg.most_recent_page_type,
    agg.store_closed_date,
    ROW_NUMBER() OVER (PARTITION BY agg.s_store_sk ORDER BY agg.total_net_loss DESC) AS store_loss_rank
FROM (
    SELECT
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        r.r_reason_desc,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_tax) AS avg_return_tax,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages_created,
        MAX(wp.wp_type) AS most_recent_page_type,
        MAX(d_closed.d_date) AS store_closed_date
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_ret.d_date_sk
    JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    GROUP BY
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        r.r_reason_desc
) agg
WHERE agg.d_year >= 2000
ORDER BY agg.total_net_loss DESC
LIMIT 100

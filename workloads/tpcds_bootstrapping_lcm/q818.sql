WITH store_ret_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        COUNT(*) AS store_return_cnt,
        AVG(sr.sr_net_loss) AS avg_store_net_loss,
        MAX(sr.sr_addr_sk) AS any_sr_addr_sk
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk
),
web_ret_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        COUNT(*) AS web_return_cnt,
        AVG(wr.wr_net_loss) AS avg_web_net_loss,
        MAX(wr.wr_refunded_addr_sk) AS any_wr_refunded_addr_sk,
        MAX(wr.wr_returning_addr_sk) AS any_wr_returning_addr_sk
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_city,
    d_clos.d_date AS store_closed_date,
    d_ret.d_date AS store_return_date,
    ca_sr.ca_state AS store_return_address_state,
    ca_wr_ref.ca_state AS web_refunded_address_state,
    ca_wr_ret.ca_state AS web_returning_address_state,
    COALESCE(sr_agg.total_store_net_loss, 0) AS total_store_net_loss,
    COALESCE(wr_agg.total_web_net_loss, 0) AS total_web_net_loss,
    COALESCE(sr_agg.total_store_net_loss, 0) + COALESCE(wr_agg.total_web_net_loss, 0) AS total_combined_net_loss,
    COALESCE(sr_agg.store_return_cnt, 0) AS store_return_cnt,
    COALESCE(wr_agg.web_return_cnt, 0) AS web_return_cnt,
    sr_agg.avg_store_net_loss,
    wr_agg.avg_web_net_loss,
    ROW_NUMBER() OVER (
        PARTITION BY s.s_store_sk
        ORDER BY COALESCE(sr_agg.total_store_net_loss, 0) + COALESCE(wr_agg.total_web_net_loss, 0) DESC
    ) AS loss_rank
FROM store s
LEFT JOIN store_ret_agg sr_agg
    ON sr_agg.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_ret
    ON sr_agg.sr_returned_date_sk = d_ret.d_date_sk
LEFT JOIN date_dim d_clos
    ON s.s_closed_date_sk = d_clos.d_date_sk
LEFT JOIN web_ret_agg wr_agg
    ON wr_agg.wr_returned_date_sk = d_clos.d_date_sk
LEFT JOIN customer_address ca_sr
    ON sr_agg.any_sr_addr_sk = ca_sr.ca_address_sk
LEFT JOIN customer_address ca_wr_ref
    ON wr_agg.any_wr_refunded_addr_sk = ca_wr_ref.ca_address_sk
LEFT JOIN customer_address ca_wr_ret
    ON wr_agg.any_wr_returning_addr_sk = ca_wr_ret.ca_address_sk
ORDER BY total_combined_net_loss DESC
LIMIT 100

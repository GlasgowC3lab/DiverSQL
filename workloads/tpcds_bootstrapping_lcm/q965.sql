WITH daily_store_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        d.d_date,
        d.d_year,
        r.r_reason_desc,
        ca_ret.ca_city AS returning_city,
        ca_ret.ca_state AS returning_state,
        ca_ref.ca_city AS refunded_city,
        ca_ref.ca_state AS refunded_state,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_quantity) AS total_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_account_credit) AS avg_account_credit
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_ret
        ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer_address ca_ref
        ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d.d_date,
        d.d_year,
        r.r_reason_desc,
        ca_ret.ca_city,
        ca_ret.ca_state,
        ca_ref.ca_city,
        ca_ref.ca_state
)
SELECT
    s_store_id,
    s_store_name,
    store_city,
    store_state,
    d_date,
    d_year,
    r_reason_desc,
    returning_city,
    returning_state,
    refunded_city,
    refunded_state,
    total_returns,
    total_quantity,
    total_return_amount,
    total_net_loss,
    avg_account_credit,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_net_loss DESC) AS loss_rank_within_store
FROM daily_store_returns
ORDER BY total_net_loss DESC, total_returns DESC
LIMIT 200

WITH aggregated AS (
    SELECT
        store.s_store_name AS store_name,
        store.s_city AS city,
        call_center.cc_name AS call_center_name,
        call_center.cc_division_name AS division_name,
        d_return.d_year AS d_year,
        d_return.d_month_seq AS d_month_seq,
        SUM(store_returns.sr_net_loss) AS total_net_loss,
        SUM(store_returns.sr_return_amt) AS total_return_amount,
        COUNT(*) AS num_returns,
        AVG(store_returns.sr_return_quantity) AS avg_return_qty,
        MIN(customer_address.ca_city) AS any_return_city,
        MAX(customer_address.ca_state) AS any_return_state
    FROM store_returns
    JOIN date_dim d_return
        ON store_returns.sr_returned_date_sk = d_return.d_date_sk
    JOIN customer_address
        ON store_returns.sr_addr_sk = customer_address.ca_address_sk
    JOIN store
        ON store_returns.sr_store_sk = store.s_store_sk
    JOIN date_dim d_store_closed
        ON store.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN call_center
        ON call_center.cc_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON call_center.cc_open_date_sk = d_cc_open.d_date_sk
    WHERE d_return.d_year = 2020
      AND store.s_state = customer_address.ca_state
    GROUP BY
        store.s_store_name,
        store.s_city,
        call_center.cc_name,
        call_center.cc_division_name,
        d_return.d_year,
        d_return.d_month_seq
    HAVING SUM(store_returns.sr_net_loss) > 0
)
SELECT
    store_name,
    city,
    call_center_name,
    division_name,
    d_year,
    d_month_seq,
    total_net_loss,
    total_return_amount,
    num_returns,
    avg_return_qty,
    any_return_city,
    any_return_state,
    CASE
        WHEN total_net_loss < 1000 THEN 'Low'
        WHEN total_net_loss < 5000 THEN 'Medium'
        ELSE 'High'
    END AS loss_category,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_loss DESC) AS loss_rank_in_month
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 100

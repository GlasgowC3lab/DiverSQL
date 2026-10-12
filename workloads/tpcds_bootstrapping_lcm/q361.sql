WITH aggregated_returns AS (
    SELECT
        s.s_store_id AS s_store_id,
        s.s_store_name AS s_store_name,
        s.s_city AS s_city,
        s.s_state AS s_state,
        d_return.d_date AS return_date,
        d_return.d_year AS return_year,
        d_store.d_date AS store_closed_date,
        d_store.d_year AS store_closed_year,
        t.t_hour AS t_hour,
        t.t_am_pm AS t_am_pm,
        ca_refunded.ca_country AS refunded_country,
        ca_refunded.ca_city AS refunded_city,
        ca_returning.ca_country AS returning_country,
        ca_returning.ca_city AS returning_city,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_quantity) AS avg_return_quantity
    FROM web_returns wr
    JOIN date_dim d_return
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer_address ca_refunded
        ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning
        ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN store s
        ON s.s_closed_date_sk = d_return.d_date_sk
    JOIN date_dim d_store
        ON s.s_closed_date_sk = d_store.d_date_sk
    WHERE d_return.d_year = 2022
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_return.d_date,
        d_return.d_year,
        d_store.d_date,
        d_store.d_year,
        t.t_hour,
        t.t_am_pm,
        ca_refunded.ca_country,
        ca_refunded.ca_city,
        ca_returning.ca_country,
        ca_returning.ca_city
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    return_date,
    return_year,
    store_closed_date,
    store_closed_year,
    t_hour,
    t_am_pm,
    refunded_country,
    refunded_city,
    returning_country,
    returning_city,
    total_returns,
    total_return_amount,
    total_net_loss,
    avg_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_return_amount DESC) AS store_return_rank
FROM aggregated_returns
ORDER BY total_return_amount DESC
LIMIT 100

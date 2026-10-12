WITH returns_aggregated AS (
    SELECT
        cc.cc_name AS call_center_name,
        cc.cc_market_manager,
        d_cc_open.d_date AS call_center_open_date,
        d_store_closed.d_date AS store_closed_date,
        s.s_store_name,
        s.s_manager,
        d_ret.d_year,
        d_ret.d_month_seq,
        ca.ca_city AS customer_city,
        ca.ca_state AS customer_state,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_amt) AS avg_return_amount,
        SUM(sr.sr_store_credit) AS total_store_credit,
        CASE
            WHEN SUM(sr.sr_net_loss) > 100000 THEN 'High'
            WHEN SUM(sr.sr_net_loss) > 50000 THEN 'Medium'
            ELSE 'Low'
        END AS net_loss_category
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d_ret.d_year = 2022
      AND s.s_state = 'CA'
    GROUP BY
        cc.cc_name,
        cc.cc_market_manager,
        d_cc_open.d_date,
        d_store_closed.d_date,
        s.s_store_name,
        s.s_manager,
        d_ret.d_year,
        d_ret.d_month_seq,
        ca.ca_city,
        ca.ca_state
)
SELECT
    call_center_name,
    cc_market_manager,
    call_center_open_date,
    store_closed_date,
    s_store_name,
    s_manager,
    d_year,
    d_month_seq,
    customer_city,
    customer_state,
    total_returns,
    total_net_loss,
    avg_return_amount,
    total_store_credit,
    net_loss_category,
    DENSE_RANK() OVER (PARTITION BY call_center_name ORDER BY total_net_loss DESC) AS store_net_loss_rank
FROM returns_aggregated
ORDER BY total_net_loss DESC
LIMIT 100

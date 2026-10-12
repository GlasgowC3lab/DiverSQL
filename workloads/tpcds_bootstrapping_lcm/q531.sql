WITH wr_data AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returning_addr_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_returning_hdemo_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_return_amt,
        wr.wr_return_amt_inc_tax,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        wr.wr_order_number,
        wr.wr_return_tax,
        wr.wr_return_ship_cost
    FROM web_returns wr
),
agg_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d.d_year,
        d.d_month_seq,
        ca_ret.ca_city AS returning_city,
        ca_ret.ca_state AS returning_state,
        ca_ref.ca_city AS refunded_city,
        ca_ref.ca_state AS refunded_state,
        hd_ret.hd_buy_potential AS returning_buy_potential,
        hd_ref.hd_buy_potential AS refunded_buy_potential,
        SUM(wr_data.wr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT wr_data.wr_order_number) AS distinct_orders,
        SUM(wr_data.wr_return_amt) AS total_return_amount,
        SUM(wr_data.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
        SUM(wr_data.wr_return_tax) AS total_return_tax,
        SUM(wr_data.wr_return_ship_cost) AS total_return_ship_cost,
        SUM(wr_data.wr_net_loss) AS total_net_loss,
        AVG(wr_data.wr_return_amt) AS avg_return_amount
    FROM wr_data
    JOIN date_dim d
        ON wr_data.wr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN customer_address ca_ret
        ON wr_data.wr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer_address ca_ref
        ON wr_data.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN household_demographics hd_ret
        ON wr_data.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN household_demographics hd_ref
        ON wr_data.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d.d_year,
        d.d_month_seq,
        ca_ret.ca_city,
        ca_ret.ca_state,
        ca_ref.ca_city,
        ca_ref.ca_state,
        hd_ret.hd_buy_potential,
        hd_ref.hd_buy_potential
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    d_year,
    d_month_seq,
    returning_city,
    returning_state,
    refunded_city,
    refunded_state,
    returning_buy_potential,
    refunded_buy_potential,
    total_return_quantity,
    distinct_orders,
    total_return_amount,
    total_return_amount_inc_tax,
    total_return_tax,
    total_return_ship_cost,
    total_net_loss,
    avg_return_amount,
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS overall_loss_rank
FROM agg_returns
ORDER BY total_net_loss DESC
LIMIT 100

WITH aggregated_returns AS (
    SELECT
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month,
        s.s_store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        i.i_category,
        i.i_brand,
        ca_returning.ca_state AS returning_state,
        ca_refunded.ca_state AS refunded_state,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_amt) AS total_return_amount,
        AVG(wr.wr_return_quantity) AS avg_return_quantity,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
        COUNT(*) AS total_returns
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    GROUP BY
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_store_name,
        s.s_city,
        s.s_state,
        i.i_category,
        i.i_brand,
        ca_returning.ca_state,
        ca_refunded.ca_state
)
SELECT
    ar.return_year,
    ar.return_month,
    ar.s_store_name,
    ar.store_city,
    ar.store_state,
    ar.i_category,
    ar.i_brand,
    ar.returning_state,
    ar.refunded_state,
    ar.total_net_loss,
    ar.total_return_amount,
    ar.avg_return_quantity,
    ar.distinct_orders,
    ar.total_returns,
    ROW_NUMBER() OVER (PARTITION BY ar.s_store_name ORDER BY ar.total_net_loss DESC) AS loss_rank_by_store
FROM aggregated_returns ar
ORDER BY ar.total_net_loss DESC
LIMIT 100

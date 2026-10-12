WITH filtered AS (
    SELECT
        i.i_brand,
        ca_refunded.ca_state AS refunded_state,
        ca_returning.ca_state AS returning_state,
        wr.wr_return_amt_inc_tax,
        wr.wr_net_loss,
        wr.wr_return_quantity,
        wr.wr_refunded_cash
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    WHERE ca_refunded.ca_country = 'United States'
      AND ca_refunded.ca_location_type = 'condo'
      AND ca_returning.ca_location_type = 'apartment'
      AND i.i_category = 'Electronics'
)
SELECT
    i_brand,
    refunded_state,
    returning_state,
    num_returns,
    total_return_amount,
    total_net_loss,
    avg_return_quantity,
    total_refunded_cash,
    RANK() OVER (PARTITION BY i_brand ORDER BY total_return_amount DESC) AS state_rank
FROM (
    SELECT
        i_brand,
        refunded_state,
        returning_state,
        COUNT(*) AS num_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amount,
        SUM(wr_net_loss) AS total_net_loss,
        AVG(wr_return_quantity) AS avg_return_quantity,
        SUM(wr_refunded_cash) AS total_refunded_cash
    FROM filtered
    GROUP BY i_brand, refunded_state, returning_state
    HAVING COUNT(*) >= 5
) agg
ORDER BY i_brand, total_return_amount DESC

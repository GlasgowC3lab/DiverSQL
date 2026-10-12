WITH store_metrics AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        s.s_city,
        s.s_division_id,
        ca.ca_city AS customer_city,
        ca.ca_county,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE s.s_division_id = 5
      AND ca.ca_county = 'Orange County'
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state, s.s_city, s.s_division_id, ca.ca_city, ca.ca_county
)
SELECT
    s_store_name,
    s_state,
    customer_city,
    total_return_amount,
    total_net_loss,
    avg_return_qty,
    return_count,
    state_net_loss_rank
FROM (
    SELECT
        s_store_name,
        s_state,
        customer_city,
        total_return_amount,
        total_net_loss,
        avg_return_qty,
        return_count,
        RANK() OVER (PARTITION BY s_state ORDER BY total_net_loss DESC) AS state_net_loss_rank
    FROM store_metrics
) ranked
WHERE state_net_loss_rank <= 3
ORDER BY total_net_loss DESC
LIMIT 10

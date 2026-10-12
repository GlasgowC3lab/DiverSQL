WITH returns_by_demo AS (
    SELECT
        ca.ca_state AS ca_state,
        hd.hd_vehicle_count AS hd_vehicle_count,
        hd.hd_buy_potential AS hd_buy_potential,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_net_loss) AS avg_net_loss,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_returned_date_sk > 2451000
    GROUP BY ca.ca_state, hd.hd_vehicle_count, hd.hd_buy_potential
)
SELECT
    ca_state,
    hd_vehicle_count,
    hd_buy_potential,
    total_net_loss,
    avg_net_loss,
    total_return_amt,
    return_cnt,
    total_return_amt / NULLIF(total_net_loss, 0) AS return_to_loss_ratio,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM returns_by_demo
WHERE avg_net_loss > 0
ORDER BY total_net_loss DESC
LIMIT 10

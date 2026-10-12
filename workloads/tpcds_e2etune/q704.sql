WITH state_income_returns AS (
    SELECT
        ca.ca_state,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_quantity) AS total_return_quantity
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ca.ca_location_type IN ('condo', 'apartment')
      AND ca.ca_state IN ('AZ', 'NM', 'PA')
      AND ca.ca_zip LIKE '8%'
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2451500
    GROUP BY ca.ca_state, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    HAVING COUNT(*) >= 10
)
SELECT
    ca_state,
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    total_net_loss,
    avg_return_amt,
    return_cnt,
    total_return_quantity,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM state_income_returns
ORDER BY total_net_loss DESC
LIMIT 20

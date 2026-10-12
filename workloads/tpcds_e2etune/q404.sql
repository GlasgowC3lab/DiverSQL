WITH aggregated AS (
    SELECT
        rc.cd_gender AS returning_gender,
        rc.cd_marital_status AS returning_marital_status,
        rhd.hd_income_band_sk AS returning_income_band,
        fc.cd_gender AS refunded_gender,
        fc.cd_marital_status AS refunded_marital_status,
        fhd.hd_vehicle_count AS refunded_vehicle_count,
        COUNT(*) AS num_returns,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amount,
        SUM(CASE WHEN wr.wr_net_loss > 100 THEN 1 ELSE 0 END) AS high_loss_count
    FROM web_returns wr
    JOIN customer_demographics rc ON wr.wr_returning_cdemo_sk = rc.cd_demo_sk
    JOIN household_demographics rhd ON wr.wr_returning_hdemo_sk = rhd.hd_demo_sk
    JOIN customer_demographics fc ON wr.wr_refunded_cdemo_sk = fc.cd_demo_sk
    JOIN household_demographics fhd ON wr.wr_refunded_hdemo_sk = fhd.hd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450905 AND 2451087
      AND rc.cd_gender = 'M'
      AND fc.cd_gender = 'F'
      AND fhd.hd_buy_potential = 'HIGH'
      AND wr.wr_net_loss > 0
    GROUP BY rc.cd_gender, rc.cd_marital_status, rhd.hd_income_band_sk, fc.cd_gender, fc.cd_marital_status, fhd.hd_vehicle_count
    HAVING COUNT(*) >= 5
)
SELECT
    returning_gender,
    returning_marital_status,
    returning_income_band,
    refunded_gender,
    refunded_marital_status,
    refunded_vehicle_count,
    num_returns,
    total_net_loss,
    avg_return_amount,
    high_loss_count,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM aggregated
ORDER BY loss_rank
LIMIT 10

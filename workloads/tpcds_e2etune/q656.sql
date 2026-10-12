WITH gender_edu_agg AS (
    SELECT
        cd.cd_gender,
        cd.cd_education_status,
        hd.hd_vehicle_count,
        SUM(sr.sr_return_amt) AS total_return_amount,
        AVG(sr.sr_net_loss) AS avg_net_loss,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_return_quantity) AS total_quantity
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE
        cd.cd_gender = 'F'
        AND cd.cd_education_status IN ('College', '4 yr Degree')
        AND hd.hd_buy_potential = 'High'
        AND sr.sr_return_amt > 100
        AND hd.hd_vehicle_count >= 2
    GROUP BY cd.cd_gender, cd.cd_education_status, hd.hd_vehicle_count
)
SELECT
    cd_gender,
    cd_education_status,
    hd_vehicle_count,
    total_return_amount,
    avg_net_loss,
    return_cnt,
    total_quantity,
    RANK() OVER (ORDER BY total_return_amount DESC) AS amount_rank
FROM gender_edu_agg
ORDER BY total_return_amount DESC
LIMIT 50

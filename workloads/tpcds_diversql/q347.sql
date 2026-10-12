WITH intersect_demo AS (
        SELECT hd_demo_sk FROM household_demographics WHERE hd_dep_count >= 5
        INTERSECT
        SELECT hd_demo_sk FROM household_demographics WHERE hd_vehicle_count >= 2
    ),
    filtered_returns AS (
        SELECT *
        FROM web_returns TABLESAMPLE BERNOULLI (10)
        WHERE wr_return_amt > 100
          AND wr_return_quantity >= 1
          AND wr_account_credit < 500
          AND wr_return_ship_cost BETWEEN 20 AND 800
    )
SELECT
    hd_refunded.hd_income_band_sk AS refunded_income_band,
    hd_returning.hd_vehicle_count AS returning_vehicle_count,
    SUM(fr.wr_return_amt) AS total_return_amount,
    SUM(fr.wr_return_quantity) AS total_return_quantity,
    SUM(fr.wr_net_loss) AS total_net_loss,
    CASE WHEN SUM(fr.wr_net_loss) > 500 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
    RANK() OVER (PARTITION BY hd_refunded.hd_income_band_sk ORDER BY SUM(fr.wr_return_amt) DESC) AS income_band_rank
FROM filtered_returns fr
JOIN household_demographics AS hd_refunded
    ON fr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics AS hd_returning
    ON fr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
WHERE hd_refunded.hd_demo_sk IN (SELECT hd_demo_sk FROM intersect_demo)
  AND hd_returning.hd_demo_sk IN (SELECT hd_demo_sk FROM intersect_demo)
  AND hd_refunded.hd_income_band_sk IN (3, 6, 18)
  AND hd_returning.hd_vehicle_count >= 2
GROUP BY
    hd_refunded.hd_income_band_sk,
    hd_returning.hd_vehicle_count
ORDER BY income_band_rank, total_return_amount DESC
LIMIT 100

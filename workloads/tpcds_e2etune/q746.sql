WITH returns_agg AS (
    SELECT
        cr.cr_ship_mode_sk,
        hd.hd_income_band_sk,
        COUNT(DISTINCT cr.cr_order_number) AS num_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_return_tax > 10.0
    GROUP BY cr.cr_ship_mode_sk, hd.hd_income_band_sk
    HAVING COUNT(DISTINCT cr.cr_order_number) > 5
),
sales_agg AS (
    SELECT
        hd.hd_income_band_sk,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_income_band_sk
)
SELECT
    sm.sm_type AS ship_mode,
    CONCAT(CAST(ib.ib_lower_bound AS VARCHAR), '-', CAST(ib.ib_upper_bound AS VARCHAR)) AS income_band,
    ra.num_returns,
    ra.total_return_amount,
    ra.total_net_loss,
    COALESCE(sa.total_store_profit, 0) AS total_store_profit,
    (COALESCE(sa.total_store_profit, 0) - ra.total_net_loss) AS profit_loss_diff,
    RANK() OVER (ORDER BY ra.total_net_loss DESC) AS loss_rank
FROM returns_agg ra
JOIN ship_mode sm
    ON ra.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN income_band ib
    ON ra.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN sales_agg sa
    ON ra.hd_income_band_sk = sa.hd_income_band_sk
WHERE sm.sm_carrier = 'UPS'
ORDER BY ra.total_net_loss DESC
LIMIT 20

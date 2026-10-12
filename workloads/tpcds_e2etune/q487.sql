WITH filtered_returns AS (
    SELECT
        sr.sr_return_quantity,
        sr.sr_net_loss,
        sr.sr_refunded_cash,
        sr.sr_return_amt,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        td.t_shift
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    WHERE hd.hd_buy_potential IN ('1001-5000', '5001-10000')
      AND hd.hd_vehicle_count >= 2
      AND td.t_shift = 'Evening'
      AND sr.sr_return_quantity > 0
)
SELECT
    fr.ib_income_band_sk,
    fr.ib_lower_bound,
    fr.ib_upper_bound,
    fr.t_shift,
    SUM(fr.sr_return_quantity) AS total_return_qty,
    SUM(fr.sr_net_loss) AS total_net_loss,
    AVG(fr.sr_refunded_cash) AS avg_refunded_cash,
    SUM(fr.sr_return_amt) AS total_return_amount,
    RANK() OVER (PARTITION BY fr.t_shift ORDER BY SUM(fr.sr_net_loss) DESC) AS net_loss_rank
FROM filtered_returns fr
GROUP BY fr.ib_income_band_sk, fr.ib_lower_bound, fr.ib_upper_bound, fr.t_shift
HAVING SUM(fr.sr_return_quantity) > 100
ORDER BY fr.t_shift, net_loss_rank

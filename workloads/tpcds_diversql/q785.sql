WITH
    sr_joined AS (
        SELECT sr.sr_hdemo_sk AS hd_demo_sk,
               sr.sr_net_loss
        FROM store_returns sr
        JOIN household_demographics hd
          ON sr.sr_hdemo_sk = hd.hd_demo_sk
        WHERE hd.hd_income_band_sk = 5
          AND sr.sr_return_ship_cost > (
                SELECT AVG(sr2.sr_return_ship_cost)
                FROM store_returns sr2
          )
    ),
    sr_agg AS (
        SELECT hd_demo_sk,
               SUM(sr_net_loss) AS total_store_loss,
               COUNT(*) AS cnt_store_returns
        FROM sr_joined
        GROUP BY hd_demo_sk
    ),
    wr_joined AS (
        SELECT wr.wr_refunded_hdemo_sk AS hd_demo_sk,
               wr.wr_net_loss
        FROM web_returns wr
        JOIN household_demographics hd
          ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        WHERE hd.hd_income_band_sk = 3
          AND wr.wr_return_tax > 10
    ),
    wr_agg AS (
        SELECT hd_demo_sk,
               SUM(wr_net_loss) AS total_web_loss,
               COUNT(*) AS cnt_web_returns
        FROM wr_joined
        GROUP BY hd_demo_sk
    ),
    full_joined AS (
        SELECT COALESCE(sr.hd_demo_sk, wr.hd_demo_sk) AS hd_demo_sk,
               sr.total_store_loss,
               sr.cnt_store_returns,
               wr.total_web_loss,
               wr.cnt_web_returns
        FROM sr_agg sr
        FULL OUTER JOIN wr_agg wr
          ON sr.hd_demo_sk = wr.hd_demo_sk
    ),
    final_union AS (
        SELECT hd_demo_sk,
               total_store_loss AS loss_amount,
               cnt_store_returns AS cnt,
               'store' AS source
        FROM full_joined
        WHERE total_store_loss IS NOT NULL
        UNION
        SELECT hd_demo_sk,
               total_web_loss AS loss_amount,
               cnt_web_returns AS cnt,
               'web' AS source
        FROM full_joined
        WHERE total_web_loss IS NOT NULL
    )
SELECT fu.hd_demo_sk,
       fu.loss_amount,
       fu.cnt,
       fu.source
FROM final_union fu
WHERE fu.loss_amount > (
        SELECT MAX(ws.ws_net_paid_inc_ship_tax)
        FROM web_sales ws
        WHERE ws.ws_coupon_amt > 1000
      )
  AND NOT EXISTS (
        SELECT 1
        FROM household_demographics hd
        WHERE hd.hd_demo_sk = fu.hd_demo_sk
          AND hd.hd_buy_potential = 'medium'
      )
ORDER BY fu.loss_amount DESC
LIMIT 100

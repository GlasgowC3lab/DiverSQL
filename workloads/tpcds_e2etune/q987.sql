WITH returns_agg AS (
    SELECT
        ib.ib_income_band_sk,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Damaged'
      AND cr.cr_returned_date_sk BETWEEN 2450800 AND 2451100
    GROUP BY ib.ib_income_band_sk
),
sales_agg AS (
    SELECT
        ib.ib_income_band_sk,
        SUM(ws.ws_net_profit) AS total_sales_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450800 AND 2451100
    GROUP BY ib.ib_income_band_sk
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(s.total_sales_profit, 0) AS total_sales_profit,
    COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0) AS net_profit,
    COALESCE(r.return_cnt, 0) AS return_cnt,
    COALESCE(s.sales_cnt, 0) AS sales_cnt
FROM income_band ib
LEFT JOIN returns_agg r ON ib.ib_income_band_sk = r.ib_income_band_sk
LEFT JOIN sales_agg s ON ib.ib_income_band_sk = s.ib_income_band_sk
ORDER BY net_profit DESC
LIMIT 20

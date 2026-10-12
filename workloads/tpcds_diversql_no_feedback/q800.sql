WITH store_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_net_profit) AS profit,
        COUNT(*) AS txn_count,
        ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS rank,
        'store' AS source_type
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_buy_potential = '>10000'
      AND ib.ib_upper_bound > 150000
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
web_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ws.ws_net_profit) AS profit,
        COUNT(*) AS txn_count,
        ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank,
        'web' AS source_type
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_link_count > 10
      AND ib.ib_lower_bound >= 100001
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_order_number = ws.ws_order_number
            AND wr.wr_return_quantity > 0
      )
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT
    c.ib_income_band_sk,
    c.ib_lower_bound,
    c.ib_upper_bound,
    c.source_type,
    c.profit,
    c.txn_count,
    c.rank,
    ROW_NUMBER() OVER (PARTITION BY c.ib_income_band_sk ORDER BY c.profit DESC) AS overall_rank,
    (SELECT SUM(ws2.ws_net_profit)
     FROM web_sales ws2
     JOIN household_demographics hd2
         ON ws2.ws_bill_hdemo_sk = hd2.hd_demo_sk
     WHERE hd2.hd_income_band_sk = c.ib_income_band_sk) AS total_web_profit_for_band
FROM combined c
ORDER BY c.ib_income_band_sk, c.profit DESC
LIMIT 100

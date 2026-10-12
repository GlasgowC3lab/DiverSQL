WITH store_income_stats AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        hd.hd_income_band_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_net_paid) AS avg_paid,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count >= 2
      AND hd.hd_buy_potential = '5001-10000'
      AND s.s_state = 'CA'
      AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910  -- roughly Jan‑Feb 2000
    GROUP BY s.s_store_id, s.s_store_name, hd.hd_income_band_sk
    HAVING SUM(ss.ss_net_profit) > 10000
)
SELECT
    sis.s_store_id,
    sis.s_store_name,
    sis.hd_income_band_sk,
    sis.total_profit,
    sis.avg_paid,
    sis.total_quantity,
    RANK() OVER (PARTITION BY sis.hd_income_band_sk ORDER BY sis.total_profit DESC) AS profit_rank
FROM store_income_stats sis
ORDER BY sis.total_profit DESC
LIMIT 10

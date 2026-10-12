WITH sales_by_cc AS (
    SELECT
        cc.cc_state,
        cc.cc_country,
        cc.cc_manager,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_net_paid) AS avg_net_paid,
        COUNT(DISTINCT ss.ss_store_sk) AS num_stores
    FROM store_sales ss
    JOIN call_center cc
        ON ss.ss_store_sk = cc.cc_call_center_sk
    WHERE cc.cc_rec_start_date >= DATE '2000-01-01'
      AND ss.ss_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY cc.cc_state, cc.cc_country, cc.cc_manager
    HAVING SUM(ss.ss_net_profit) > 100000
)
SELECT
    cc_state,
    cc_country,
    cc_manager,
    total_net_profit,
    avg_net_paid,
    num_stores,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_by_cc
ORDER BY total_net_profit DESC
LIMIT 50

WITH sales_by_band AS (
    SELECT
        ib.ib_income_band_sk AS income_band_id,
        ib.ib_lower_bound AS lower_bound,
        ib.ib_upper_bound AS upper_bound,
        cc.cc_manager AS call_center_manager,
        cc.cc_state AS state,
        ws.web_name AS web_site_name,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN income_band ib
        ON ss.ss_quantity BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    JOIN call_center cc
        ON ss.ss_sold_date_sk = cc.cc_open_date_sk
    JOIN web_site ws
        ON cc.cc_state = ws.web_state
       AND cc.cc_country = ws.web_country
    WHERE cc.cc_country = 'United States'
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound,
             cc.cc_manager, cc.cc_state,
             ws.web_name
    HAVING SUM(ss.ss_net_paid) > 10000
)
SELECT
    income_band_id,
    lower_bound,
    upper_bound,
    call_center_manager,
    state,
    web_site_name,
    num_transactions,
    total_net_paid,
    avg_discount,
    total_net_profit,
    RANK() OVER (PARTITION BY call_center_manager ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_by_band
ORDER BY total_net_profit DESC
LIMIT 100

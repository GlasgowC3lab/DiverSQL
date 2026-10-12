WITH aggregated AS (
    SELECT
        ib.ib_lower_bound AS lower_bound,
        ib.ib_upper_bound AS upper_bound,
        ws.web_site_id,
        ws.web_name,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN income_band ib
        ON ss.ss_cdemo_sk = ib.ib_income_band_sk
    JOIN web_page wp
        ON ss.ss_customer_sk = wp.wp_customer_sk
    JOIN web_site ws
        ON wp.wp_web_page_id = ws.web_site_id
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451200
      AND ws.web_state = 'CA'
    GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, ws.web_site_id, ws.web_name
    HAVING SUM(ss.ss_net_profit) > 1000
)
SELECT
    lower_bound,
    upper_bound,
    web_site_id,
    web_name,
    total_profit,
    avg_discount,
    total_quantity,
    RANK() OVER (PARTITION BY lower_bound, upper_bound ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY total_profit DESC
LIMIT 50

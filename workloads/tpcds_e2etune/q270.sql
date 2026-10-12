WITH sales_agg AS (
    SELECT 
        cs.cs_bill_hdemo_sk AS hd_demo_sk,
        ca.ca_state AS state,
        sm.sm_type AS ship_mode_type,
        SUM(cs.cs_net_profit) AS total_sales_profit
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_net_profit > 0
      AND ca.ca_zip LIKE '98%'
    GROUP BY cs.cs_bill_hdemo_sk, ca.ca_state, sm.sm_type
),
returns_agg AS (
    SELECT 
        cr.cr_refunded_hdemo_sk AS hd_demo_sk,
        ca.ca_state AS state,
        sm.sm_type AS ship_mode_type,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_return_quantity > 5
      AND ca.ca_zip LIKE '98%'
    GROUP BY cr.cr_refunded_hdemo_sk, ca.ca_state, sm.sm_type
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(s.state, r.state) AS state,
    COALESCE(s.ship_mode_type, r.ship_mode_type) AS ship_mode_type,
    COALESCE(s.total_sales_profit, 0) AS total_sales_profit,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0) AS net_contribution
FROM sales_agg s
FULL OUTER JOIN returns_agg r
    ON s.hd_demo_sk = r.hd_demo_sk
   AND s.state = r.state
   AND s.ship_mode_type = r.ship_mode_type
JOIN household_demographics hd
    ON COALESCE(s.hd_demo_sk, r.hd_demo_sk) = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE (COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_return_loss, 0)) > 1000
ORDER BY net_contribution DESC
LIMIT 20

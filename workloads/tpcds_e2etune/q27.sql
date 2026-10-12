WITH catalog_agg AS (
    SELECT
        cc.cc_state,
        sm.sm_type,
        hd.hd_income_band_sk,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
      AND cc.cc_state IN ('TN', 'LA')
    GROUP BY cc.cc_state, sm.sm_type, hd.hd_income_band_sk
),
store_agg AS (
    SELECT
        hd.hd_income_band_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_return_loss
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY hd.hd_income_band_sk
)
SELECT
    ca.cc_state,
    ca.sm_type,
    ca.hd_income_band_sk,
    ca.catalog_net_profit,
    ca.catalog_sales_amount,
    ca.catalog_orders,
    sa.store_net_profit,
    sa.store_sales_amount,
    sa.store_transactions,
    sa.total_return_loss,
    (ca.catalog_net_profit + sa.store_net_profit - sa.total_return_loss) AS overall_net_contribution,
    RANK() OVER (ORDER BY (ca.catalog_net_profit + sa.store_net_profit - sa.total_return_loss) DESC) AS revenue_rank
FROM catalog_agg ca
LEFT JOIN store_agg sa ON ca.hd_income_band_sk = sa.hd_income_band_sk
WHERE (ca.catalog_net_profit + sa.store_net_profit - sa.total_return_loss) > 0
ORDER BY overall_net_contribution DESC
LIMIT 100

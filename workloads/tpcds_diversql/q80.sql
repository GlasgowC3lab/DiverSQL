WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        ca.ca_state,
        ca.ca_address_sk,
        sm.sm_type,
        p.p_discount_active,
        p.p_cost,
        sr.sr_net_loss,
        r.r_reason_desc,
        ws.ws_net_paid,
        ws.ws_order_number,
        ws.ws_item_sk,
        wp.wp_type,
        wsite.web_site_id,
        wsite.web_suite_number
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON sr.sr_hdemo_sk = hd.hd_demo_sk AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
)
SELECT
    base.web_site_id,
    base.ca_state,
    base.ib_upper_bound,
    SUM(base.cs_net_paid) AS total_sales_net_paid,
    SUM(base.sr_net_loss) AS total_store_returns_loss,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_returns_loss,
    COUNT(DISTINCT base.cs_order_number) AS distinct_sales_orders,
    AVG(base.p_cost) AS avg_promo_cost,
    MIN(base.ws_net_paid) AS min_ws_net_paid,
    MAX(base.ws_net_paid) AS max_ws_net_paid
FROM base
FULL OUTER JOIN web_returns wr
    ON wr.wr_item_sk = base.ws_item_sk
   AND wr.wr_order_number = base.ws_order_number
WHERE
    base.ca_state = 'CA'
    AND base.ib_upper_bound > 80000
    AND base.p_discount_active = 'Y'
GROUP BY
    base.web_site_id,
    base.ca_state,
    base.ib_upper_bound
ORDER BY total_sales_net_paid DESC
LIMIT 100

WITH ss_filtered AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_profit,
        ss.ss_ticket_number
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
),
agg AS (
    SELECT
        d.d_year,
        i.i_category,
        s.s_store_name AS s_store_name,
        COUNT(DISTINCT ssf.ss_ticket_number) AS orders,
        SUM(ssf.ss_quantity) AS total_quantity,
        SUM(ssf.ss_sales_price) AS total_sales,
        AVG(ssf.ss_net_profit) AS avg_profit,
        MAX(CASE WHEN cc.cc_name IS NOT NULL THEN cc.cc_name ELSE 'No Call Center' END) AS sample_call_center
    FROM ss_filtered ssf
    JOIN date_dim d ON ssf.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ssf.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ssf.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ssf.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ssf.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ssf.ss_promo_sk = p.p_promo_sk
    LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk AND cc.cc_market_manager = 'John Doe'
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_item_sk = i.i_item_sk
    LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk AND ws.web_state = 'CA'
    WHERE ca.ca_location_type = 'apartment'
      AND i.i_color = 'Red'
      AND p.p_channel_dmail = 'Y'
      AND sm.sm_code = 'AIR'
    GROUP BY d.d_year, i.i_category, s.s_store_name
)
SELECT
    d_year,
    i_category,
    s_store_name,
    orders,
    total_quantity,
    total_sales,
    avg_profit,
    sample_call_center,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_sales DESC) AS rn
FROM agg
ORDER BY total_sales DESC
LIMIT 100

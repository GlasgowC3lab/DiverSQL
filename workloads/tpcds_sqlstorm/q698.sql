WITH unified_sales AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_store_sk AS location_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_discount_amt AS discount_amt,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_call_center_sk AS location_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amt,
        'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_ship_mode_sk AS location_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS discount_amt,
        'web' AS channel
    FROM web_sales ws
),
location_dim AS (
    SELECT
        cc.cc_call_center_sk AS location_sk,
        'catalog' AS channel,
        cc.cc_state AS state
    FROM call_center cc
    UNION ALL
    SELECT
        s.s_store_sk AS location_sk,
        'store' AS channel,
        s.s_state AS state
    FROM store s
    UNION ALL
    SELECT
        sm.sm_ship_mode_sk AS location_sk,
        'web' AS channel,
        NULL AS state
    FROM ship_mode sm
),
aggregated AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        loc.channel,
        loc.state,
        SUM(u.quantity) AS total_quantity,
        SUM(u.net_paid) AS total_net_paid,
        SUM(u.net_profit) AS total_net_profit,
        AVG(u.discount_amt) AS avg_discount,
        COUNT(*) AS transaction_count
    FROM unified_sales u
    JOIN date_dim d ON u.sold_date_sk = d.d_date_sk
    JOIN location_dim loc ON u.location_sk = loc.location_sk AND u.channel = loc.channel
    WHERE d.d_year = 2000
    GROUP BY
        d.d_year,
        d.d_month_seq,
        loc.channel,
        loc.state
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.channel,
    a.state,
    a.total_quantity,
    a.total_net_paid,
    a.total_net_profit,
    a.avg_discount,
    a.transaction_count,
    RANK() OVER (PARTITION BY a.d_year, a.d_month_seq ORDER BY a.total_net_paid DESC) AS revenue_rank
FROM aggregated a
ORDER BY
    a.d_year,
    a.d_month_seq,
    a.channel

WITH sales_data AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        cc.cc_state AS state,
        'catalog' AS channel,
        cs.cs_net_profit AS net_profit,
        cs.cs_net_paid_inc_tax AS net_paid,
        cs.cs_quantity AS quantity,
        cs.cs_ext_discount_amt / NULLIF(cs.cs_ext_sales_price, 0) AS discount_rate
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 1998
),
store_data AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        s.s_state AS state,
        'store' AS channel,
        ss.ss_net_profit AS net_profit,
        ss.ss_net_paid_inc_tax AS net_paid,
        ss.ss_quantity AS quantity,
        ss.ss_ext_discount_amt / NULLIF(ss.ss_ext_sales_price, 0) AS discount_rate
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 1998
),
web_data AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        ca.ca_state AS state,
        'web' AS channel,
        ws.ws_net_profit AS net_profit,
        ws.ws_net_paid_inc_tax AS net_paid,
        ws.ws_quantity AS quantity,
        ws.ws_ext_discount_amt / NULLIF(ws.ws_ext_sales_price, 0) AS discount_rate
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 1998
),
combined AS (
    SELECT * FROM sales_data
    UNION ALL
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM web_data
),
agg AS (
    SELECT
        channel,
        d_year,
        month_seq,
        i_category,
        state,
        SUM(net_profit) AS total_net_profit,
        SUM(net_paid) AS total_net_paid,
        SUM(quantity) AS total_quantity,
        AVG(discount_rate) AS avg_discount_rate
    FROM combined
    GROUP BY channel, d_year, month_seq, i_category, state
    HAVING SUM(net_profit) > 0
)
SELECT
    channel,
    d_year,
    month_seq,
    i_category,
    state,
    total_net_profit,
    total_net_paid,
    total_quantity,
    avg_discount_rate,
    RANK() OVER (PARTITION BY channel, d_year, month_seq ORDER BY total_net_profit DESC) AS profit_rank,
    AVG(total_net_profit) OVER (
        PARTITION BY channel, i_category, state
        ORDER BY month_seq
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS profit_3mo_moving_avg
FROM agg
ORDER BY channel, d_year, month_seq, total_net_profit DESC
LIMIT 100

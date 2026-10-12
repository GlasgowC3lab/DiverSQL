WITH base AS (
    SELECT
        cc.cc_division_name,
        cc.cc_street_type,
        cc.cc_mkt_id,
        d.d_year,
        d.d_qoy,
        d.d_current_year,
        t.t_meal_time,
        t.t_sub_shift,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        sr.sr_return_quantity,
        sr.sr_return_amt
    FROM tpcds.call_center cc
    JOIN tpcds.date_dim d
        ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    WHERE cc.cc_division_name IN ('able', 'cally')
        AND cc.cc_street_type = 'Drive'
        AND cc.cc_mkt_id = 5
        AND d.d_qoy = 3
        AND d.d_current_year = 'Y'
        AND t.t_meal_time = 'lunch'
        AND t.t_sub_shift = 'morning'
        AND ss.ss_net_profit > 0
        AND sr.sr_return_quantity > 0
        AND NOT EXISTS (
            SELECT 1
            FROM tpcds.store_returns sr2
            WHERE sr2.sr_ticket_number = ss.ss_ticket_number
                AND sr2.sr_return_quantity > 5
                AND sr2.sr_returned_date_sk = d.d_date_sk
                AND sr2.sr_item_sk = ss.ss_item_sk
        )
),
agg AS (
    SELECT
        cc_division_name,
        d_year,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(sr_return_amt) AS total_returns,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS num_transactions,
        AVG(ss_net_profit) AS avg_profit
    FROM base
    GROUP BY cc_division_name, d_year
),
ranked AS (
    SELECT
        cc_division_name,
        d_year,
        total_sales,
        total_returns,
        total_profit,
        num_transactions,
        avg_profit,
        ROW_NUMBER() OVER (PARTITION BY cc_division_name ORDER BY total_profit DESC) AS rn
    FROM agg
)
SELECT
    cc_division_name,
    d_year,
    total_sales,
    total_returns,
    total_profit,
    num_transactions,
    avg_profit
FROM ranked
WHERE rn <= 3
ORDER BY cc_division_name, rn
LIMIT 100

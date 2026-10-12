WITH intersected_tickets AS (
    SELECT ss_ticket_number FROM store_sales WHERE ss_quantity > 5
    INTERSECT
    SELECT sr_ticket_number FROM store_returns WHERE sr_return_amt > 200
),
base AS (
    SELECT 
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_return_amt,
        sr.sr_reason_sk,
        r.r_reason_desc,
        d.d_date,
        d.d_year,
        ca.ca_city,
        ca.ca_gmt_offset,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        ws.web_name,
        ws.web_open_date_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND ca.ca_state = 'CA'
      AND hd.hd_income_band_sk IN (8, 9, 20)
      AND ss.ss_ticket_number IN (SELECT ss_ticket_number FROM intersected_tickets)
),
lateral_counts AS (
    SELECT 
        b.*,
        lr.cnt_same_reason
    FROM base b
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS cnt_same_reason
        FROM store_returns sr2
        WHERE sr2.sr_reason_sk = b.sr_reason_sk
          AND sr2.sr_returned_date_sk = b.ss_sold_date_sk
    ) lr
)
SELECT
    lc.ss_ticket_number,
    lc.d_date,
    lc.web_name,
    lc.ca_city,
    lc.ca_gmt_offset,
    lc.hd_income_band_sk,
    lc.hd_vehicle_count,
    lc.ss_quantity,
    lc.ss_net_paid,
    lc.ss_net_profit,
    lc.sr_return_amt,
    lc.r_reason_desc,
    lc.cnt_same_reason,
    COUNT(DISTINCT lc.ss_item_sk) OVER (PARTITION BY lc.ss_store_sk) AS distinct_items_per_store,
    COUNT(DISTINCT lc.ca_city) OVER (PARTITION BY lc.ss_store_sk) AS distinct_cities_per_store,
    ROW_NUMBER() OVER (PARTITION BY lc.ss_store_sk ORDER BY lc.ss_net_paid DESC) AS sales_rank,
    LAG(lc.ss_net_paid) OVER (PARTITION BY lc.ss_store_sk ORDER BY lc.ss_sold_date_sk) AS prev_net_paid,
    SUM(lc.ss_net_paid) OVER (PARTITION BY lc.ss_store_sk ORDER BY lc.ss_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net_paid
FROM lateral_counts lc
ORDER BY lc.ss_store_sk, sales_rank
LIMIT 100

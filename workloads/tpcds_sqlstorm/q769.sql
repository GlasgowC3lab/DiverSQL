WITH
store_agg AS (
    SELECT
        ss.ss_customer_sk AS cust_sk,
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS store_qty,
        MAX(dd.d_date) AS latest_store_date,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt
    FROM store_sales ss
    LEFT JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE (dd.d_year = 2002 OR dd.d_year IS NULL)
    GROUP BY ss.ss_customer_sk, ss.ss_item_sk
),
web_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_quantity) AS web_qty,
        MAX(dd.d_date) AS latest_web_date,
        COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt
    FROM web_sales ws
    LEFT JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE (dd.d_year = 2002 OR dd.d_year IS NULL)
    GROUP BY ws.ws_bill_customer_sk, ws.ws_item_sk
),
store_only_cust AS (
    SELECT cust_sk FROM store_agg
    EXCEPT
    SELECT cust_sk FROM web_agg
),
combined AS (
    SELECT
        COALESCE(s.cust_sk, w.cust_sk) AS cust_sk,
        COALESCE(s.item_sk, w.item_sk) AS item_sk,
        s.store_net_profit,
        s.store_qty,
        w.web_net_profit,
        w.web_qty,
        s.latest_store_date,
        w.latest_web_date,
        s.store_txn_cnt,
        w.web_txn_cnt
    FROM store_agg s
    FULL OUTER JOIN web_agg w
        ON s.cust_sk = w.cust_sk AND s.item_sk = w.item_sk
)
SELECT
    c.c_customer_id,
    CONCAT_WS(' ', c.c_first_name, c.c_last_name) AS full_name,
    COALESCE(c.c_preferred_cust_flag, 'N') AS pref_flag,
    i.i_product_name,
    i.i_category,
    combined.store_net_profit,
    combined.web_net_profit,
    (COALESCE(combined.store_net_profit, 0) - COALESCE(combined.web_net_profit, 0)) AS profit_diff,
    CASE
        WHEN (COALESCE(combined.store_net_profit, 0) - COALESCE(combined.web_net_profit, 0)) > 1000 THEN 'HIGH_DIFF'
        WHEN (COALESCE(combined.store_net_profit, 0) - COALESCE(combined.web_net_profit, 0)) < -1000 THEN 'LOW_DIFF'
        ELSE 'NORMAL_DIFF'
    END AS diff_category,
    (SELECT SUM(sr.sr_net_loss) FROM store_returns sr WHERE sr.sr_customer_sk = combined.cust_sk) AS total_store_refund,
    (SELECT SUM(wr.wr_net_loss) FROM web_returns wr WHERE wr.wr_refunded_customer_sk = combined.cust_sk) AS total_web_refund,
    SUM(COALESCE(combined.store_net_profit, 0) + COALESCE(combined.web_net_profit, 0))
        OVER (ORDER BY (COALESCE(combined.store_net_profit, 0) + COALESCE(combined.web_net_profit, 0)) DESC
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_total_profit,
    RANK() OVER (ORDER BY (COALESCE(combined.store_net_profit, 0) + COALESCE(combined.web_net_profit, 0)) DESC) AS profit_rank,
    CONCAT('CUST', LPAD(CAST(c.c_customer_sk AS VARCHAR), 8, '0'), '-',
           CASE WHEN combined.latest_store_date IS NULL THEN 'NS' ELSE format_datetime(combined.latest_store_date, 'yyyyMMdd') END,
           '-',
           CASE WHEN combined.latest_web_date IS NULL THEN 'NW' ELSE format_datetime(combined.latest_web_date, 'yyyyMMdd') END) AS custom_key,
    NULLIF(COALESCE(combined.store_net_profit, 0) + COALESCE(combined.web_net_profit, 0), 0) AS net_profit_nonzero,
    DATE_DIFF('day',
        COALESCE(combined.latest_store_date, DATE '1970-01-01'),
        COALESCE(combined.latest_web_date, DATE '1970-01-01')) AS days_between_latest,
    (SELECT COUNT(*) FROM promotion p WHERE p.p_item_sk = combined.item_sk) AS promo_count,
    (SELECT SUM(inv_quantity_on_hand) FROM inventory inv WHERE inv.inv_item_sk = combined.item_sk) AS total_inventory_on_hand,
    CASE WHEN combined.cust_sk IN (SELECT cust_sk FROM store_only_cust) THEN 1 ELSE 0 END AS store_only_flag
FROM combined
JOIN customer c ON combined.cust_sk = c.c_customer_sk
LEFT JOIN item i ON combined.item_sk = i.i_item_sk
WHERE
    (c.c_preferred_cust_flag = 'Y' OR (combined.store_net_profit IS NOT NULL AND combined.web_net_profit IS NOT NULL))
    AND c.c_email_address IS NOT NULL
    AND NOT REGEXP_LIKE(c.c_email_address, '@test\\.com$')
    AND (
        (combined.store_net_profit > 0 AND combined.web_net_profit > 0)
        OR (combined.store_net_profit IS NULL AND combined.web_net_profit IS NULL)
    )
ORDER BY profit_rank
LIMIT 10

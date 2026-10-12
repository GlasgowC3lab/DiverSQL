WITH item_words AS (
    SELECT i.i_item_sk,
           i.i_category,
           word
    FROM tpcds.item i
    CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
),

sales_agg AS (
    SELECT
        hd.hd_buy_potential,
        i.i_category,
        sm.sm_type,
        'sales' AS source,
        SUM(cs.cs_net_paid) AS amount,
        COUNT(*) AS txn_count
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY CUBE (hd.hd_buy_potential, i.i_category, sm.sm_type)
),

returns_agg AS (
    SELECT
        hd.hd_buy_potential,
        i.i_category,
        sm.sm_type,
        'returns' AS source,
        SUM(cr.cr_return_amount) AS amount,
        COUNT(*) AS txn_count
    FROM tpcds.catalog_returns cr
    JOIN tpcds.customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY CUBE (hd.hd_buy_potential, i.i_category, sm.sm_type)
),

combined AS (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
)
SELECT DISTINCT
    c.hd_buy_potential,
    c.i_category,
    c.sm_type,
    c.source,
    c.amount,
    c.txn_count,
    w.word
FROM combined c
LEFT JOIN item_words w
    ON c.i_category = w.i_category
WHERE c.amount IS NOT NULL
ORDER BY c.amount DESC, c.source
LIMIT 100

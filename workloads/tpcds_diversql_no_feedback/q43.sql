WITH agg AS (
    SELECT
        s.s_state AS store_state,
        i.i_category AS item_category,
        SUM(wr.wr_return_amt) AS sum_return_amt,
        SUM(wr.wr_return_quantity) AS sum_return_qty,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE s.s_state = 'TX'
      AND cc.cc_state = 'TX'
      AND ib.ib_lower_bound >= 10000
      AND d.d_year = 2001
      AND i.i_category = 'Sports'
      AND inv.inv_quantity_on_hand > 0
    GROUP BY GROUPING SETS (
        (s.s_state, i.i_category),
        (s.s_state),
        (i.i_category)
    )
),
ranked AS (
    SELECT
        store_state,
        item_category,
        sum_return_amt,
        sum_return_qty,
        avg_inventory_qty,
        distinct_customers,
        ROW_NUMBER() OVER (PARTITION BY store_state ORDER BY sum_return_amt DESC) AS rn
    FROM agg
    WHERE store_state IS NOT NULL
      AND item_category IS NOT NULL
)
SELECT
    store_state,
    item_category,
    sum_return_amt,
    sum_return_qty,
    avg_inventory_qty,
    distinct_customers,
    rn
FROM ranked
WHERE rn <= 3
ORDER BY store_state, rn
LIMIT 100

WITH inv_sample AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
)
SELECT
    s.s_store_name,
    d.d_year,
    i.i_brand,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    MAX(inv_max.max_qty) AS max_inventory_on_hand,
    COUNT(DISTINCT w.w_warehouse_id) AS warehouses_involved
FROM
    store_returns sr
    RIGHT OUTER JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inv_sample inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
        AND p.p_start_date_sk = d.d_date_sk
    LEFT JOIN call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN LATERAL (
        SELECT MAX(inv2.inv_quantity_on_hand) AS max_qty
        FROM inventory inv2
        WHERE inv2.inv_item_sk = i.i_item_sk
          AND inv2.inv_date_sk = d.d_date_sk
    ) AS inv_max ON TRUE
WHERE
    d.d_year = 2001
    AND s.s_state = 'CA'
    AND i.i_brand = 'Brand#12'
    AND w.w_county = 'Bronx County'
    AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_discount_active = 'Y'
    )
GROUP BY
    s.s_store_name,
    d.d_year,
    i.i_brand,
    inv_max.max_qty
ORDER BY
    total_return_amount DESC
LIMIT 100

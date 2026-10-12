WITH store AS (
    SELECT
        i.i_category,
        r.r_reason_desc,
        SUM(sr.sr_net_loss) AS net_loss,
        SUM(sr.sr_return_quantity) AS qty_returned,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_txns,
        0 AS catalog_txns,
        0 AS web_txns
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY i.i_category, r.r_reason_desc
),
catalog AS (
    SELECT
        i.i_category,
        r.r_reason_desc,
        SUM(cr.cr_net_loss) AS net_loss,
        SUM(cr.cr_return_quantity) AS qty_returned,
        SUM(cr.cr_return_amount) AS total_return_amt,
        0 AS store_txns,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_txns,
        0 AS web_txns
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY i.i_category, r.r_reason_desc
),
web AS (
    SELECT
        i.i_category,
        r.r_reason_desc,
        SUM(wr.wr_net_loss) AS net_loss,
        SUM(wr.wr_return_quantity) AS qty_returned,
        SUM(wr.wr_return_amt) AS total_return_amt,
        0 AS store_txns,
        0 AS catalog_txns,
        COUNT(DISTINCT wr.wr_order_number) AS web_txns
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY i.i_category, r.r_reason_desc
),
combined AS (
    SELECT
        i_category,
        r_reason_desc,
        SUM(net_loss) AS total_net_loss,
        SUM(qty_returned) AS total_qty_returned,
        SUM(total_return_amt) AS total_return_amount,
        SUM(store_txns) AS total_store_txns,
        SUM(catalog_txns) AS total_catalog_txns,
        SUM(web_txns) AS total_web_txns
    FROM (
        SELECT * FROM store
        UNION ALL
        SELECT * FROM catalog
        UNION ALL
        SELECT * FROM web
    ) u
    GROUP BY i_category, r_reason_desc
)
SELECT
    c.i_category,
    c.r_reason_desc,
    c.total_net_loss,
    c.total_qty_returned,
    c.total_return_amount,
    c.total_store_txns,
    c.total_catalog_txns,
    c.total_web_txns,
    inv_agg.inv_quantity_on_hand_total
FROM combined c
JOIN (
    SELECT
        i.i_category,
        SUM(inv.inv_quantity_on_hand) AS inv_quantity_on_hand_total
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_category
) inv_agg
    ON c.i_category = inv_agg.i_category
WHERE c.total_net_loss > 0
ORDER BY c.total_net_loss DESC
LIMIT 100

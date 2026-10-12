WITH
    sampled_store_returns AS (
        SELECT * FROM store_returns TABLESAMPLE BERNOULLI (10)
    ),
    store_items AS (
        SELECT DISTINCT sr_item_sk AS i_item_sk FROM sampled_store_returns
    ),
    catalog_items AS (
        SELECT DISTINCT cr_item_sk AS i_item_sk FROM catalog_returns
    ),
    common_items AS (
        SELECT i_item_sk FROM store_items INTERSECT SELECT i_item_sk FROM catalog_items
    )
SELECT
    s.s_division_id,
    s.s_division_name,
    COUNT(DISTINCT i.i_item_sk) AS common_item_cnt,
    SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss) AS total_net_loss,
    ROW_NUMBER() OVER (
        PARTITION BY s.s_division_id
        ORDER BY (SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss)) DESC
    ) AS division_rank
FROM
    common_items ci
    JOIN item i ON i.i_item_sk = ci.i_item_sk
    JOIN sampled_store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN web_page wp ON wp.wp_customer_sk = c_refunded.c_customer_sk
    JOIN customer_address ca_current ON c_refunded.c_current_addr_sk = ca_current.ca_address_sk
WHERE
    s.s_floor_space > 8000000
GROUP BY
    s.s_division_id,
    s.s_division_name
HAVING
    (SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss)) > 10000
ORDER BY
    total_net_loss DESC
LIMIT 100

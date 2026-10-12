WITH
    inv_agg AS (
        SELECT
            inv_item_sk,
            inv_date_sk,
            SUM(inv_quantity_on_hand) AS total_qty_on_hand,
            MAX(inv_warehouse_sk) AS max_warehouse_sk
        FROM inventory
        GROUP BY inv_item_sk, inv_date_sk
    ),
    sampled_wp AS (
        SELECT *
        FROM web_page
        TABLESAMPLE BERNOULLI (10)
    ),
    common_items AS (
        SELECT cr_item_sk AS item_sk FROM catalog_returns WHERE cr_return_quantity > 0
        INTERSECT
        SELECT ss_item_sk FROM store_sales WHERE ss_quantity > 0
    ),
    ca_customers AS (
        SELECT COUNT(*) AS cnt
        FROM customer c
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        WHERE ca.ca_state = 'CA'
    )
SELECT
    d.d_year,
    s.s_state,
    p.p_promo_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_loss,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_return_loss,
    SUM(ia.total_qty_on_hand) AS total_inventory_qty,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 0 THEN 'POS' ELSE 'NEG' END AS sales_sign,
    (SELECT cnt FROM ca_customers) AS ca_customer_count
FROM
    date_dim d
    FULL OUTER JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    FULL OUTER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
                               AND s.s_store_sk = sr.sr_store_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                              AND wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                                 AND cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN sampled_wp wp ON wp.wp_creation_date_sk = d.d_date_sk
                             AND wp.wp_customer_sk = c.c_customer_sk
    LEFT JOIN inv_agg ia ON ia.inv_item_sk = ss.ss_item_sk
                           AND ia.inv_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND ia.max_warehouse_sk IN (7, 12)
    AND c.c_birth_month = 5
    AND ss.ss_item_sk IN (SELECT item_sk FROM common_items)
    AND EXISTS (SELECT 1 FROM web_returns wr2 WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk)
GROUP BY ROLLUP (d.d_year, s.s_state, p.p_promo_name)
HAVING SUM(ss.ss_ext_sales_price) > 1000
ORDER BY d.d_year, s.s_state, p.p_promo_name
LIMIT 100

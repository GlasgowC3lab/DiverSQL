WITH
    /* Customers who had a catalog return with a sizable amount */
    cr_customers AS (
        SELECT DISTINCT cr.cr_refunded_customer_sk AS customer_sk
        FROM catalog_returns cr
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        WHERE cr.cr_return_amount > 100.00               -- predicate 1
          AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100  -- predicate 2 (surrogate key range)
    ),

    /* Customers who bought on the web site managed by Jason Silva after 2000 */
    ws_customers AS (
        SELECT DISTINCT ws.ws_bill_customer_sk AS customer_sk
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        WHERE wsite.web_manager = 'Jason Silva'                     -- predicate 3
          AND wsite.web_rec_start_date > DATE '2000-01-01'          -- predicate 4
          AND ws.ws_quantity > 1
    ),

    /* Customers common to both previous sets */
    common_customers AS (
        SELECT customer_sk FROM cr_customers
        INTERSECT
        SELECT customer_sk FROM ws_customers
    ),

    /* Customers who have store sales but never appeared in catalog returns */
    store_only_customers AS (
        SELECT ss.ss_customer_sk AS customer_sk
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        WHERE ss.ss_quantity > 5                                   -- predicate 5
        EXCEPT
        SELECT cr.cr_refunded_customer_sk FROM catalog_returns cr
    ),

    /* Aggregated metrics per customer‑reason‑promotion using a CUBE */
    agg AS (
        SELECT
            c.c_customer_sk,
            r.r_reason_desc,
            p.p_promo_name,
            SUM(ss.ss_ext_sales_price)               AS total_sales,
            AVG(ss.ss_ext_sales_price)               AS avg_sales,
            COUNT(*)                                 AS txn_count,
            CASE WHEN SUM(ss.ss_ext_sales_price) > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_category
        FROM store_sales ss
        JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE i.i_current_price > 20.00
        GROUP BY CUBE (c.c_customer_sk, r.r_reason_desc, p.p_promo_name)
    )
SELECT
    agg.c_customer_sk,
    agg.r_reason_desc,
    agg.p_promo_name,
    agg.total_sales,
    agg.avg_sales,
    agg.txn_count,
    agg.sales_category,
    ca_small.ca_state
FROM agg
CROSS JOIN (
    SELECT ca_state
    FROM customer_address
    WHERE ca_state IN ('TX', 'CA')
    LIMIT 2
) AS ca_small
WHERE agg.c_customer_sk IN (SELECT customer_sk FROM common_customers)
  AND agg.c_customer_sk NOT IN (SELECT customer_sk FROM store_only_customers)
ORDER BY agg.total_sales DESC
LIMIT 100

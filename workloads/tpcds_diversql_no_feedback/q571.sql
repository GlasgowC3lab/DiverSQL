WITH base AS (
    SELECT
        i.i_category,
        ca.ca_state,
        p.p_promo_name,
        SUM(cs.cs_net_paid) AS total_catalog_net_paid,
        SUM(ss.ss_net_paid) AS total_store_net_paid,
        COUNT(*) AS txn_count,
        AVG(i.i_current_price) AS avg_item_price,
        MAX(ca.ca_gmt_offset) AS max_gmt_offset
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
       AND ss.ss_addr_sk = ca.ca_address_sk
       AND ss.ss_promo_sk = p.p_promo_sk
    WHERE cs.cs_quantity > 30
      AND cs.cs_ext_wholesale_cost BETWEEN 500 AND 2000
      AND ca.ca_gmt_offset = -5.00
      AND i.i_class = 'pants'
      AND p.p_discount_active = 'Y'
      AND ss.ss_quantity < 50
    GROUP BY i.i_category, ca.ca_state, p.p_promo_name
),
subset_exclude AS (
    SELECT
        i_category,
        ca_state,
        p_promo_name,
        total_catalog_net_paid,
        total_store_net_paid,
        txn_count,
        avg_item_price,
        max_gmt_offset
    FROM base
    WHERE total_store_net_paid < 10000
)
SELECT
    i_category,
    ca_state,
    p_promo_name,
    total_catalog_net_paid,
    total_store_net_paid,
    txn_count,
    avg_item_price,
    max_gmt_offset
FROM base
EXCEPT
SELECT
    i_category,
    ca_state,
    p_promo_name,
    total_catalog_net_paid,
    total_store_net_paid,
    txn_count,
    avg_item_price,
    max_gmt_offset
FROM subset_exclude
LIMIT 100

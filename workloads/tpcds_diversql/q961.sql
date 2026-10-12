WITH
store_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        AVG(ss.ss_quantity) AS avg_quantity
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'                         -- filter 1
      AND i.i_category = 'Sports'                  -- filter 2
      AND ib.ib_upper_bound = 150000               -- filter 3
    GROUP BY ss.ss_item_sk, ss.ss_store_sk
),
catalog_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        SUM(cs.cs_net_paid) AS cat_total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        MIN(cs.cs_sales_price) AS min_price
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cc.cc_class = 'large'                     -- filter 4
      AND cp.cp_type = 'A'                          -- filter 5
    GROUP BY cs.cs_item_sk, cs.cs_call_center_sk
),
store_returns_agg AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_tickets
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE r.r_reason_desc = 'Damaged'               -- filter 6
    GROUP BY sr.sr_item_sk
),
catalog_returns_agg AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_net_loss) AS cat_return_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cp.cp_department = 'Electronics'         -- filter 7
    GROUP BY cr.cr_item_sk
),
intersect_items AS (
    SELECT ss_item_sk AS item_sk FROM store_agg
    INTERSECT
    SELECT cs_item_sk AS item_sk FROM catalog_agg
),
store_full AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        sa.total_net_paid,
        sa.distinct_tickets
    FROM store s
    FULL OUTER JOIN store_agg sa ON s.s_store_sk = sa.ss_store_sk
),
final_agg AS (
    SELECT
        ii.item_sk,
        sa.total_net_paid,
        ca.cat_total_net_paid,
        (sa.total_net_paid + ca.cat_total_net_paid) AS combined_net_paid,
        sr.total_net_loss,
        cr.cat_return_net_loss,
        COUNT(DISTINCT sf.s_store_name) AS distinct_stores,
        SUM(DISTINCT ss_sub.quantity) AS sum_distinct_quantity,
        AVG(DISTINCT ss_sub.quantity) AS avg_distinct_quantity
    FROM intersect_items ii
    JOIN store_agg sa ON ii.item_sk = sa.ss_item_sk
    JOIN catalog_agg ca ON ii.item_sk = ca.cs_item_sk
    LEFT JOIN store_returns_agg sr ON ii.item_sk = sr.sr_item_sk
    LEFT JOIN catalog_returns_agg cr ON ii.item_sk = cr.cr_item_sk
    LEFT JOIN store_full sf ON sf.s_store_sk = sa.ss_store_sk
    LEFT JOIN LATERAL (
        SELECT SUM(ss_quantity) AS quantity
        FROM store_sales ss
        WHERE ss.ss_item_sk = ii.item_sk
    ) ss_sub ON TRUE
    WHERE ii.item_sk NOT IN (SELECT i_item_sk FROM item WHERE i_brand = 'BrandX')
    GROUP BY ii.item_sk,
             sa.total_net_paid,
             ca.cat_total_net_paid,
             sr.total_net_loss,
             cr.cat_return_net_loss,
             sf.s_store_name,
             ss_sub.quantity
)
SELECT *
FROM final_agg
LIMIT 100
